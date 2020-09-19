-- A more elegant readline from a more civilized age. Less convoluted than 
-- Monolith's. --

local function readline(opts)
  checkArg(1, opts, "table", "nil")
  opts = opts or {}
  local prompt = opts.prompt or ""
  local arrows if opts.arrows == nil then arrows = true end
  local buf = {}
  io.write("\27[108;8m")
  while true do
    local c = io.read(1)
    if c == "\27" then
      repeat
        local n = io.read(1)
        c = c .. n
      until not n:match("[%d;]")
    end
  end
  io.write("\27[0m")
  return buf
end

return readline
