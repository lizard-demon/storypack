-- ddl - direct download

local http = require("socket.http")

return function(t)
  local body = assert(http.request(t.url))
  local f = assert(io.open(t.path, "w"))
  f:write(body)
  f:close()
end

