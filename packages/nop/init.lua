local M = {}
local http = require("socket.http")
local ltn12 = require("ltn12")

local function sync_csv()
  local url = "https://docs.google.com/spreadsheets/d/1nOtYmv_d6Qt1tCX_63uE2yWVFs6-G5x_XJ778lD9qyU/export?format=csv&gid=941242858"
  local path = "platforms/nop.csv"
  local etagfile = "platforms/.nop.csv.etag"
  
  local etag = io.open(etagfile, "r")
  etag = etag and etag:read("*l") or ""
  
  local body = {}
  local _, code, headers = http.request{
    url = url,
    sink = ltn12.sink.table(body),
    headers = { ["If-None-Match"] = etag }
  }
  
  if code == 200 and headers.etag then
    local out = io.open(path, "wb")
    out:write(table.concat(body))
    out:close()
    local meta = io.open(etagfile, "w")
    meta:write(headers.etag)
    meta:close()
    return true
  end
  return false
end

local function parse_csv(file)
  local rows = {}
  for line in io.lines(file) do
    local row = {}
    local i, quote = 1, false
    for field in (line .. ","):gmatch('(.-),') do
      if field:match('^".*"$') then
        row[i] = field:sub(2, -2):gsub('""', '"')
      else
        row[i] = field
      end
      i = i + 1
    end
    if #row > 1 then rows[#rows + 1] = row end
  end
  return rows
end

local function hash_rows(rows)
  local s = ""
  for _, row in ipairs(rows) do
    s = s .. table.concat(row, "|") .. "\n"
  end
  return tostring(s:len()) .. ":" .. s:sub(1, 100)
end

local function fetch_reddit_json(url)
  local body = {}
  local _, code = http.request{
    url = url .. "/.json",
    sink = ltn12.sink.table(body)
  }
  if code == 200 then
    local json_str = table.concat(body)
    -- Minimal JSON parse for Reddit structure
    local title = json_str:match('"title"%s*:%s*"([^"]*)"')
    local author = json_str:match('"author"%s*:%s*"([^"]*)"')
    local selftext = json_str:match('"selftext"%s*:%s*"([^"]*)"')
    if selftext then
      selftext = selftext:gsub('\\n', '\n'):gsub('\\"', '"'):gsub('\\\\', '\\')
    end
    return title, author, selftext
  end
end

local function create_epub(story, posts, main_author)
  local html_parts = {"<html><head><title>" .. story.title .. "</title></head><body>"}
  
  for _, post in ipairs(posts) do
    local title, author, body = post[1], post[2], post[3]
    table.insert(html_parts, "<h2>" .. title .. "</h2>")
    table.insert(html_parts, "<p><em>by u/" .. author .. "</em></p>")
    table.insert(html_parts, "<div>" .. body:gsub('\n', '<br/>') .. "</div><hr/>")
  end
  
  table.insert(html_parts, "</body></html>")
  local html = table.concat(html_parts)
  
  local backend = EpubDownloadBackend
  return backend:createEpub(story.file, html, "", false, story.title, false, nil)
end

function M.handle(story)
  local csv_updated = sync_csv()
  if not csv_updated then return end
  
  local rows = parse_csv("platforms/nop.csv")
  local headers = rows[1]
  local filtered = {}
  
  for i = 3, #rows do -- Skip header and description rows
    if story.filter(rows[i], headers) then
      filtered[#filtered + 1] = rows[i]
    end
  end
  
  local new_hash = hash_rows(filtered)
  local hashfile = story.file:match("(.*/)") .. "." .. story.file:match("([^/]+)$") .. ".hash"
  local old_hash = io.open(hashfile, "r")
  old_hash = old_hash and old_hash:read("*l") or ""
  
  if new_hash == old_hash then return end
  
  local posts = {}
  local authors = {}
  
  for _, row in ipairs(filtered) do
    local link_idx = 7 -- Link column
    local url = row[link_idx]
    if url and url:match("reddit%.com") then
      local title, author, body = fetch_reddit_json(url)
      if body and body ~= "" then
        posts[#posts + 1] = {title, author, body}
        authors[#authors + 1] = author
      end
    end
  end
  
  if #posts > 0 then
    -- Find most common author
    local author_counts = {}
    for _, a in ipairs(authors) do
      author_counts[a] = (author_counts[a] or 0) + 1
    end
    local main_author = "Anonymous"
    local max_count = 0
    for a, c in pairs(author_counts) do
      if c > max_count then
        main_author = a
        max_count = c
      end
    end
    
    if create_epub(story, posts, main_author) then
      local hash_out = io.open(hashfile, "w")
      hash_out:write(new_hash)
      hash_out:close()
      return "updated " .. #posts .. " posts"
    end
  end
end

return M
