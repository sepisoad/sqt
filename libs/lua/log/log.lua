_G.VERBOSE = false
local level = { INFO = "info", DBG = "debug", ERR = "error", WARN = "warning" }

--[[
This function prints a message with a log level to standard output.

@param msg is the message to be logged.
@param lvl is the level of the to be logged message.
]]
local print_log = function(msg, ext, lvl)
  assert(msg ~= nil and msg ~= "")
  assert(lvl ~= nil)

  msg = string.format("[%s]: %s", lvl, msg)
  if ext ~= nil and ext ~= "" then
    msg = string.format("%s\n details: %s", ext)
  end
  print(msg)
end

--[[
This function prints a message with an 'info' log level to standard output.

@param msg is the message to be logged.
]]
local print_info = function(msg, ext)
  print_log(msg, ext, level.INFO)
end

--[[
This function prints a message with an 'debug' log level to standard output.

@param msg is the message to be logged.
]]
local print_dbg = function(msg, ext)
  if _G.VERBOSE then
    print_log(msg, ext, level.DBG)
  end
end

--[[
This function prints a message with an 'warning' log level to standard output.

@param msg is the message to be logged.
]]
local print_warn = function(msg, ext)
  print_log(msg, ext, level.WARN)
end

--[[
This function prints a message with an 'error' log level to standard output.

@param msg is the message to be logged.
]]
local print_err = function(msg, ext)
  print_log(msg, ext, level.ERR)
end

return {
  info = print_info,
  dbg = print_dbg,
  warn = print_warn,
  err = print_err,
  VERBOSE = VERBOSE
}
