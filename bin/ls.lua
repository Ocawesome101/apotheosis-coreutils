-- ls --

local fs = require("filesystem")
local argutil = require("args")

local args, opts = argutil.parse(...)

if opts.help then
  print([[
Usage: ls [OPTION]... [FILE]...
List information about FILEs (the current directory by default).
Sort options alphabetically.
]])
end

local dir
local pwd = os.getenv("PWD")
if #args == 0 then dir = pwd end

local files = fs.list(dir)
table.sort(files)
for i=1, #files, 1 do io.write(files[i].."\t") end
print("")
