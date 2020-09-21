-- ls --

local fs = require("filesystem")
local shutil = require("shutil")

local args, opts = shutil.parse(...)

local pwd = os.getenv("PWD")
