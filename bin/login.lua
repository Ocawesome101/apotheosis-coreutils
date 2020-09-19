-- login --

local hostname = require("hostname")

while true do
  io.write("\27[2J\27[1H")
  local names = hostname.get()
  io.write((names.minitel or names.gert or names.standard) .. " login: ")
  while true do coroutine.yield() end
end
