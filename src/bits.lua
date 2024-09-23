---@param file file*
---@return string
ReadAll = function (file)
  return file:read("a")
end

---@param file file*
---@return any
WriteAll = function (file, data)
  return file:write(data)
end

---@param file file*
---@param size integer
---@return any
ReadBuf = function (file, size)
  return file:read(size)
end

---@param file file*
---@param size integer
---@return string
ReadChars = function (file, size)
  local code = "c"..size
  return string.pack(code, file:read(size))
end

---@param file file*
---@param str string
---@param size integer
WriteChars = function (file, str, size)
  local code = "c"..size
  file:write(string.pack(code, str))
end

---@param file file*
---@param size integer
---@return string
ReadCStr = function (file, size)
  return string.unpack("z", file:read(size))
end

---@param file file*
---@param size integer
---@return integer
ReadI32 = function (file, size)
  return string.unpack("=i", file:read(size))
end

---@param file file*
---@param size integer
WriteI32 = function (file, size)
  file:write(string.pack("=i", size))
end

---@param file file*
---@param size integer
---@return integer
ReadU8 = function (file, size)
  return string.unpack("=B", file:read(size))
end

---@param file file*
---@param size integer
WriteU8 = function (file, size)
  file:write(string.pack("=B", size))
end

