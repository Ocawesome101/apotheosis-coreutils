-- fmt - basic text formatting utility --

local argp = require("argp")
local path = require("path")
local libvt = require("libvt")

local args, opts = argp.parse(...)

if opts.help then
  io.stderr:write([[
Usage: fmt [OPTIONS]... [FILE]
Basic text formatting utility.  See fmt(1) and
fmt(7).
]])
  os.exit(0)
end

local w, h = libvt.getResolution()
local file, err = io.open(path.resolve(args[1]), "r")
if not file then
  io.stderr:write(err, "\n")
  os.exit(1)
end

local data = file:read("a")
file:close()
local buffer = ""
local written = 0
local inEsc, esc = false, char
for char in data:gmatch(".") do
  if inEsc == 1 then
    if char == "\\" then
      inEsc = false
      buffer = buffer .. char
    elseif char == "t" then
      buffer = buffer .. "        "
      inEsc = false
      esc = nil
    elseif char:match("[cCbB]") then
      inEsc = 2
      esc = char
    end
  elseif inEsc == 2 then
    local base = (esc == "c" and 30) or
                (esc == "C" and 40) or
                (esc == "b" and 90) or
                (esc == "B" and 100)
    buffer = string.format("%s\27[%dm", buffer, base + tonumber(char))
    inEsc = false
    esc = nil
  elseif char == "\\" then
    inEsc = 1
  else
    buffer = buffer .. char
  end
end

io.write(buffer, "\27[39m\n")

if not io.output().tty then
  io.output():close()
end

os.exit(0)
