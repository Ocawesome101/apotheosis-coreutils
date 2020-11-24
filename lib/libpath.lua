-- file path utility functions --

local lib = {}

local fs = require("filesystem")

function lib.concat(...)
  local args = table.pack(...)
  for i=1, args.n, 1 do
    checkArg(i, args[i], "string")
  end
  return "/" .. (table.concat(args, "/"):gsub("([/\\]+)", "/"))
end

function lib.resolve(path)
  checkArg(1, path, "string")
  if path:sub(1,1) ~= "/" then
    local pwd = os.getenv("PWD")
    local try = lib.concat(pwd, path)
    if fs.stat(try) then
      return try
    end
  else
    return path
  end
  return nil, path..": file not found"
end

return lib
