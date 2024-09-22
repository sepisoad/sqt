_G.VERBOSE = false

---@enum level
local LEVEL = { INFO = "info", DBG = "debug", ERR = "error", WARN = "warning" }


---@param msg string
---@param ext string?
---@param lvl level
local print_log = function(msg, ext, lvl)
  assert(msg ~= nil and msg ~= "")
  assert(lvl ~= nil)

  msg = string.format("[%s]: %s", lvl, msg)
  if ext ~= nil and ext ~= "" then
    msg = string.format("%s\n details: %s", msg, ext)
  end
  print(msg)
end

---@param msg string
---@param ext string?
local print_info = function(msg, ext)
  print_log(msg, ext, LEVEL.INFO)
end

---@param msg string
---@param ext string?
local print_dbg = function(msg, ext)
  if _G.VERBOSE then
    print_log(msg, ext, LEVEL.DBG)
  end
end

---@param msg string
---@param ext string?
local print_warn = function(msg, ext)
  print_log(msg, ext, LEVEL.WARN)
end

---@param msg string
---@param ext string?
local print_err = function(msg, ext)
  print_log(msg, ext, LEVEL.ERR)
end

return {
  info = print_info,
  dbg = print_dbg,
  warn = print_warn,
  err = print_err,
  VERBOSE = VERBOSE
}
