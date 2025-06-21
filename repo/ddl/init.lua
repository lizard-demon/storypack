local http, ltn12 = require("socket.http"), require("ltn12")
local M = {}

function M.handle(story)
  if not story.url:match("%.epub$") then return end
  local statef = "." .. story.file .. ".state"
  local hdr = io.open(statef, "r")
  local h = hdr and { ["If-Modified-Since"] = hdr:read("*a") } or {}
  if hdr then hdr:close() end

  local body, t = {}, ltn12.sink.table{}
  local _, code, res = http.request{url=story.url, headers=h, sink=t}
  if code == 304 then return end

  io.open(story.file, "w"):write(table.concat(t)):close()
  if res["last-modified"] then io.open(statef, "w"):write(res["last-modified"]):close() end
  print("Updated:", story.title)
end

return M

