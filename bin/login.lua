-- login --

local hostname = require("hostname")

while true do
  io.write("\27[1H\27[0m\27[2J")
  print(string.format("\n%s %s\n", _KINFO.name, _KINFO.version))
  local hnames = hostname.get()
  io.write((hnames.minitel or hnames.gert or hnames.standard or "localhost") .. " login: ")
  local name = io.read()
  io.write("password: \27[8m")
  local pass = io.read()
  io.write("\27[0m")

  local ok, err = loadfile("/bin/sh.lua")
  if not ok then
    print("error in shell: " .. err)
  else
  end
  os.sleep(5)
end
