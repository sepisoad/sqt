---@param file file*
---@return string
local read_all = function (file)
  return file:read("a")
end

---@param file file*
---@return any
local write_all = function (file, data)
  return file:write(data)
end

---@param file file*
---@param size integer
---@return any
local read_buf = function (file, size)
  return file:read(size)
end

---@param file file*
---@param size integer
---@return string
local read_chars = function (file, size)
  local code = "c"..size
  return string.pack(code, file:read(size))
end

---@param file file*
---@param str string
---@param size integer
local write_chars = function (file, str, size)
  local code = "c"..size
  file:write(string.pack(code, str))
end

---@param file file*
---@param size integer
---@return string
local read_c_str = function (file, size)
  return string.unpack("z", file:read(size))
end

---@param file file*
---@param size integer
---@return integer
local read_i32 = function (file, size)
  return string.unpack("=i", file:read(size))
end

---@param file file*
---@param size integer
local write_i32 = function (file, size)
  file:write(string.pack("=i", size))
end

---@param file file*
---@param size integer
---@return integer
local read_u8 = function (file, size)
  return string.unpack("=B", file:read(size))
end

---@param file file*
---@param size integer
local write_u8 = function (file, size)
  file:write(string.pack("=B", size))
end

return {
  r_all = read_all,
  w_all = write_all,
  r_buf = read_buf,
  r_chrs = read_chars,
  w_chrs = write_chars,
  r_cstr = read_c_str,
  r_i32 = read_i32,
  w_i32 = write_i32,
  r_u8 = read_u8,
  w_u8 = write_u8,
}