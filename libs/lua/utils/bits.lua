local BYTE_SIZE <const> = 1
local SHORT_SIZE <const> = BYTE_SIZE * 2
local INTEGER_SIZE <const> = SHORT_SIZE * 2
local LONG_SIZE <const> = INTEGER_SIZE * 2
local FLOAT_SIZE <const> = INTEGER_SIZE
local DOUBLE_SIZE <const> = LONG_SIZE

---========================================
--- READER
---========================================

--- read_byte
---@param f file*
---@param signed boolean|nil
---@return integer
local read_byte = function (f, signed)
  local fmt = "=B"
  if signed then fmt = "=b" end
  return string.unpack(fmt, f:read(BYTE_SIZE))
end

--- read_short
--- @param f file*
--- @param signed boolean|nil
--- @returns integer
local read_short = function (f, signed)
  local fmt = "=H"
  if signed then fmt = "=h" end
  return string.unpack(fmt, f:read(SHORT_SIZE))
end

--- read_integer
--- @param f file*
--- @param signed boolean|nil
--- @returns integer
local read_integer = function (f, signed)
  local fmt = "=I"
  if signed then fmt = "=i" end
  return string.unpack(fmt, f:read(INTEGER_SIZE))
end

--- read_long
--- @param f file*
--- @param signed boolean|nil
--- @returns integer
local read_long = function (f, signed)
  local fmt = "=L"
  if signed then fmt = "=l" end
  return string.unpack(fmt, f:read(LONG_SIZE))
end

--- read_float
--- @param f file*
--- @param double boolean|nil
--- @returns number
local read_float = function (f, double)
  if double then
    return string.unpack("=d", f:read(DOUBLE_SIZE))
  end
  return string.unpack("=f", f:read(FLOAT_SIZE))
end

--- read_size
--- @param f file*
--- @returns integer
local read_size = function (f)
  local fmt = "=T"
  return string.unpack(fmt, f:read(INTEGER_SIZE))
end

--- read_string
--- @param f file*
--- @param size integer
--- @returns string
local read_string = function (f, size)
  local fmt = "c" .. size
  return string.unpack(fmt, f:read(size))
end

--- read_cstring
--- @param f file*
--- @param size integer
--- @returns string
local read_cstring = function (f, size)
  local fmt = "z"
  return string.unpack(fmt, f:read(size))
end

--- read_line
--- @param f file*
--- @returns string
local read_line = function (f)
  return f:read("l")
end

--- read_all
---@param f file*
---@return string
local read_all = function (f)
  return f:read("a")
end

--- read_all
---@param f file*
---@param length integer
---@return any
local read_bytes = function (f, length)
  return f:read(length)
end

---========================================
--- WRITER
---========================================

--- write_byte
---@param f file*
---@param value integer
---@param signed boolean|nil
---@return file*|nil
local write_byte = function (f, value, signed)
  local fmt = "=B"
  if signed then fmt = "=b" end
  return f:write(string.pack(fmt, value))
end

--- write_short
---@param f file*
---@param value integer
---@param signed boolean|nil
---@return file*|nil
local write_short = function (f, value, signed)
  local fmt = "=H"
  if signed then fmt = "=h" end
  return f:write(string.pack(fmt, value))
end

--- write_integer
---@param f file*
---@param value integer
---@param signed boolean|nil
---@return file*|nil
local write_integer = function (f, value, signed)
  local fmt = "=I"
  if signed then fmt = "=i" end
  return f:write(string.pack(fmt, value))
end

--- write_long
---@param f file*
---@param value integer
---@param signed boolean|nil
---@return file*|nil
local write_long = function (f, value, signed)
  local fmt = "=L"
  if signed then fmt = "=l" end
  return f:write(string.pack(fmt, value))
end

--- write_size
---@param f file*
---@param value integer
---@param signed boolean|nil
---@return file*|nil
local write_size = function (f, value, signed)
  local fmt = "=T" -- always the same!
  return f:write(string.pack(fmt, value))
end

--- write_float
---@param f file*
---@param value number
---@param double boolean|nil
---@return file*|nil
local write_float = function (f, value, double)
  if double then
    return f:write(string.pack("=d", value))
  end
  return f:write(string.pack("=f", value))
end

--- write_string
---@param f file*
---@param value string
---@param size integer
---@return file*|nil
local write_string = function (f, value, size)
  local fmt = "c" .. size
  return f:write(string.pack(fmt, value))
end

--- write_all
---@param f file*
---@param value any
---@return file*|nil
local write_all = function (f, value)
  return f:write(value)
end

---========================================
--- MODULE
---========================================

return {
  reader = {
    byte = read_byte,
    short = read_short,
    integer = read_integer,
    long = read_long,
    size = read_size,
    float = read_float,
    string = read_string,
    cstring = read_cstring,
    line = read_line,
    all = read_all,
    bytes = read_bytes,
  },
  writer = {
    byte = write_byte,
    short = write_short,
    integer = write_integer,
    long = write_long,
    size = write_size,
    float = write_float,
    string = write_string,
    all = write_all,
  }
}