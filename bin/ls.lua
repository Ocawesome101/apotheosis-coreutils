-- ls --

local fs = require("filesystem")
local argp = require("libargp")
local libvt = require("libvt")
local paths = require("libpath")

local args, opts = argp.parse(...)

if opts.help then
  print([[
Usage: ls [OPTION]... [FILE]...
List information about FILEs (the current directory by default).
Sort options alphabetically.
]])
  os.exit(0)
end

local w, h = libvt.getResolution()

local dir
local pwd = os.getenv("PWD")
if #args == 0 then dir = pwd end
if not dir then dir = pwd or "/" end

local dat = fs.stat(dir)
if not dat then
  print(dir..": no such directory")
  os.exit(1)
end

if not dat.isDirectory then
  print(dir..": not a directory")
  os.exit(1)
end

local files = fs.list(dir)
table.sort(files)

local formatted = ""

local maxN = 1
if not opts.l then
  -- find the longest file entry
  for i=1, #files, 1 do
    if #files[i] > maxN then
      maxN = #files[i]
    end
  end
  maxN = maxN + 2
end
if maxN >= w then
  opts["1"] = true
end

for i=1, #files, 1 do
  if opts.l then
    local full = paths.concat(dir, files[i] or "")
    local info, err = fs.stat(full)
    if not info then
      print(err)
      os.exit(1)
    end
  end
end

