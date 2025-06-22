return function (t)
  local http = require("socket.http")
  local ltn12 = require("ltn12")

  local etagfile = t.path:match("(.*/)") .. "." .. t.path:match("([^/]+)$") .. ".etag"

  local etag = io.open(etagfile, "r")
  etag = etag and etag:read("*l") or ""

  local body = {}
  local _, code, headers = http.request{
    url = t.url,
    sink = ltn12.sink.table(body),
    headers = { ["If-None-Match"] = etag }
  }

  if code == 200 and headers.etag then
    local out = io.open(t.path, "wb")
    out:write(table.concat(body))
    out:close()
    local meta = io.open(etagfile, "w")
    meta:write(headers.etag)
    meta:close()
    return "updated"
  end
end
