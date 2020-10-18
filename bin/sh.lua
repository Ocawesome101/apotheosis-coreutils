-- sh - basic shell --

local fs = require("filesystem")
local pipe = require("pipe")
local process = require("process")
local computer = require("computer")

os.setenv("PWD", os.getenv("PWD") or "/")
os.setenv("PATH", os.getenv("PATH") or "/bin:/sbin")
os.setenv("SHLVL", (os.getenv("SHLVL") or "0") + 1)

local pgsub = {
  ["\\w"] = function()
    return (os.getenv("PWD") and os.getenv("PWD"):gsub("^"..os.getenv("HOME").."?", "~")) or "/"
  end,
  ["\\W"] = function() return os.getenv("PWD"):match("%/(.+)$") end,
  ["\\h"] = function() return os.getenv("HOSTNAME") end,
  ["\\s"] = function() return "sh" end,
  ["\\v"] = function() return "0.1.0" end,
  ["\\a"] = function() return "\a" end
}

-- TODO: move a bunch of this to a common library
local builtins = {
  exit = function()
    os.exit()
  end
}

local function parse_prompt(prompt)
  local ret = prompt
  for pat, rep in pairs(pgsub) do
    ret = ret:gsub(pat, rep() or "")
  end
  return ret
end

local function split_tokens(str)
  local ret = {}
  for token in str:gmatch("[^%s]+") do
    ret[#ret+1] = token
  end
  return ret
end

-- "a | b > c" -> {{cmd = {"a"}, i = <std>, o = <pipe>}, {cmd = {"b"}, i = <pipe>, o = <handle_to_c>}}
local function setup(str)
  local tokens = split_tokens(str)
  local stdin = io.input()
  local stdout = io.output()
  local ret = {}
  local cur = {cmd = {}, i = stdin, o = stdout}
  local i = 1
  while i <= #tokens do
    local t = tokens[i]
    if t == "|" then
      if #cur.cmd == 0 or i == #tokens then
        return nil, "syntax error near unexpected token `|`"
      end
      local new = pipe.create()
      cur.o = new
      table.insert(ret, cur)
      cur = {cmd = {}, i = pipe, o = stdout}
    elseif t == ">" or t == ">>" then -- > write, >> append
      if #cur.cmd == 0 or i == #tokens then
        return nil, "syntax error near unexpected token `"..t.."`"
      end
      i = i + 1
      local handle, err = io.open(tokens[i], t == ">" and "w" or "a")
      if not handle then
        return nil, err
      end
      cur.o = handle
    elseif t == "<" then
      if #cur.cmd == 0 or i == #tokens then
        return nil, "syntax error near unexpected token `<`"
      end
      i = i + 1
      local handle, err = io.open(tokens[i], "r")
      if not handle then
        return nil, err
      end
      cur.i = handle
    else
      cur.cmd[#cur.cmd + 1] = t
    end
    i = i + 1
  end
  if #cur.cmd > 0 then
    table.insert(ret, cur)
  end
  return ret
end

local function concat(...)
  return "/" .. (table.concat(table.pack(...), "/"):gsub("[/\\]+", "/"))
end

local function resolve(cmd)
  if fs.exists(cmd) then
    return cmd
  end
  if fs.exists(cmd..".lua") then
    return cmd..".lua"
  end
  for path in os.getenv("PATH"):gmatch("[^:]+") do
    local check = concat(path, cmd)
    if fs.exists(check) then
      return check
    end
    if fs.exists(check..".lua") then
      return check..".lua"
    end
  end
  return nil, cmd..": command not found"
end

-- this should be simple, right? just loadfile() and spawn functions
local function execute(str)
  local exec, err = setup(str)
  if not exec then
    return nil, err
  end
  local pids = {}
  local errno = false
  for i=1, #exec, 1 do
    local func
    local ex = exec[i]
    local cmd = ex.cmd[1]
    if builtins[cmd] then
      func = builtins[cmd]
    else
      local path, err = resolve(cmd)
      if not path then
        return nil, err
      end
      local ok, err = loadfile(path)
      if not ok then
        return nil, err
      end
      func = ok
    end
    local f = function()
      io.input(ex.i)
      io.output(ex.o)
      local ok, ret = pcall(func, table.unpack(ex.cmd, 2))
      if not ok and ret then
        errno = ret
        io.stderr:write(ret,"\n")
        for i=1, #pids, 1 do
          process.signal(pids[i], process.signals.SIGKILL)
        end
      end
    end
    table.insert(pids, process.spawn(f, table.concat(ex.cmd, " ")))
  end
  computer.pushSignal("sh_dummy")
  while true do
    local run = false
    for k, pid in pairs(pids) do
      if process.info(pid) then
        run = true
      end
    end
    coroutine.yield()
    if errno or not run then break end
  end
  if errno then
    return nil, errno
  end
  return true
end

os.setenv("PS1", os.getenv("PS1") or "\\s-\\v$ ")

while true do
  io.write(parse_prompt(os.getenv("PS1")))
  local input, ierr = io.read("l")
  if not input and ierr then print(ierr) end
  if input then
    local ok, err = execute(input)
    if not ok then
    --  print(err)
    end
  end
end
