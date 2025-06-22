-- ao3 - Convert AO3 URL to .epub download link then sync it.

local http = require("socket.http")

return function(url, dir)

    local id = url:match("/works/(%d+)")
    if not id then error("Invalid AO3 URL") end

    local body = assert(http.request(url))
    local title = body:match("<title>(.-) %-")
    if not title then error("Title not found") end
    title = title:gsub(" ", "_")

    return require("sync") {
      url = (("https://archiveofourown.org/downloads/%s/%s.epub"):format(id, title)),
      path = (dir .. "/" .. title),
    }
end
