-- vt100 abstractions / utilities --

local vt = {}

function vt.setCursor(x, y)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  if not (io.stdout.tty) then
    return
  end
  io.write(string.format("\27[%d;%dH", y, x))
end

function vt.getCursor()
  if not (io.stdin.tty and io.stdout.tty) then
    return 1, 1
  end
  io.write("\27[6n\27(l")
  local resp = ""
  repeat
    local c = io.read(1)
    resp = resp .. c
  until c == "R"
  io.write("\27(L")
  local y, x = resp:match("\27%[(%d+);(%d+)R")
--  require("component").sandbox.log(resp, x, y)
  return tonumber(x), tonumber(y)
end

function vt.getResolution()
  if not (io.stdin.tty and io.stdout.tty) then
    return 1, 1
  end
  local x, y = vt.getCursor()
  vt.setCursor(9999, 9999)
  local w, h = vt.getCursor()
  vt.setCursor(x, y)
  return w, h
end

return vt
