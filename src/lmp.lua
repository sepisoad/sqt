require('libs.lua.app.types')
local log = require('libs.lua.log.log')
local paths = require('libs.lua.utils.paths')
local qoi = require('libs.lua.image.qoi')

--- -----------------------------------------------
---@param p string
---@return file*
local open_lump_file = function(p)
  log.dbg(string.format("openning the .LMP file from '%s'", p))

  local lump_f, err = io.open(p, "rb")
  if not lump_f then
    log.err(string.format("failed to open '%s'", p), err)
    os.exit(1)
  end

  return lump_f
end

--- -----------------------------------------------
---@param p string
---@return any
local load_qoi_data = function(p)
  log.dbg(string.format("openning the .qoi file from '%s'", p))

  local qoi_f, qoi_data, err

  qoi_f, err = io.open(p, "rb")
  if not qoi_f then
    log.err(string.format("failed to open '%s'", p), err)
    os.exit(1)
  end


  qoi_data, err = qoi_f:read("a")
  if not qoi_data then
    log.err(string.format("failed to read the '%s' data", p), err)
    os.exit(1)
  end

  return qoi_data
end

--- -----------------------------------------------
---@param p string
---@return file*
local open_palette_file = function(p)
  log.dbg(string.format("openning the .LMP pallete file from '%s'", p))

  local palette_f, err = io.open(p, "rb")
  if not palette_f then
    log.err(string.format("failed to open lump pallete '%s'", p), err)
    os.exit(1)
  end

  return palette_f
end

--- -----------------------------------------------
---@param palette_f file*
local get_palette_size = function(palette_f)
  log.dbg("calclulating palette size")

  local plt_fsize = palette_f:seek("end", 0)
  palette_f:seek("set", 0)
  return plt_fsize
end

--- -----------------------------------------------
---@param size integer
local verify_palette = function(palette_file_path, size)
  log.dbg(string.format("verifying palette file '%s'", palette_file_path))

  if size <= 0 then
    print("err: the palette '" .. palette_file_path .. "' file is not valid")
    os.exit()
  end
end

--- -----------------------------------------------
---@param palette_f file*
---@param palette_size integer
---@return PaletteData
local load_palette_data = function(palette_f, palette_size)
  log.dbg("loading palette color data")

  ---@type PaletteData
  local colors = { Colors = {} }
  local rgb_size = RGBColor_.Red + RGBColor_.Green + RGBColor_.Blue
  local num_of_colors = palette_size // rgb_size

  for _ = 1, num_of_colors do
    ---@type RGBColor
    local RGB = {
      Red = string.unpack("=B", palette_f:read(RGBColor_.Red)),
      Green = string.unpack("=B", palette_f:read(RGBColor_.Green)),
      Blue = string.unpack("=B", palette_f:read(RGBColor_.Blue))
    }
    table.insert(colors, RGB)
  end
  return colors
end

--- -----------------------------------------------
---@param lump_header LumpHeader
---@param palette_data PaletteData
---@return any
local convert_lump_to_qoi = function(lump_file_path, palette_file_path, lump_header, palette_data)
  log.dbg("converting lump image to qoi")

  local qoi_data = nil
  local err = nil

  qoi_data, err = qoi.encode_indexed(lump_header.Data, palette_data, lump_header.Width, lump_header.Height)
  if err then
    log.err(string.format("failed to decode '%s' using '%s' to qoi", lump_file_path, palette_file_path), err)
    os.exit(1)
  end
  return qoi_data
end

--- -----------------------------------------------
---@param qoi_data file*
---@param palette_data any
---@param qoi_file_path string
---@return LumpHeader
local convert_qoi_to_lump = function(qoi_data, palette_data, qoi_file_path)
  log.dbg("converting qoi image to lump")

  local lump_data, lump_width, lump_height = qoi.decode_indexed(qoi_data, palette_data)
  if not lump_data then
    log.err(string.format("failed to convert qoi data to lump data from '%s'", qoi_file_path))
    os.exit(1)
  end

  ---@type LumpHeader
  local lump_header = {
    Width = lump_width,
    Height = lump_height,
    Data = lump_data
  }

  return lump_header
end

--- -----------------------------------------------
---@param lump_header LumpHeader
---@param lump_file_path string
local save_lump_file = function(lump_header, lump_file_path)
  log.dbg(string.format("saving LMP data into %s", lump_file_path))

  local lump_f, err = io.open(lump_file_path, "wb")
  if not lump_f then
    log.err(string.format("failed to open '%s' for writing LMP data", lump_file_path), err)
    os.exit(1)
  end

  lump_f:write(string.pack("=i", lump_header.Width))
  lump_f:write(string.pack("=i", lump_header.Height))
  lump_f:write(lump_header.Data)

  lump_f:close()
end

--- -----------------------------------------------
---@param file_path string
local create_toplevel_dir_for_output_file = function(file_path)
  log.dbg(string.format("creating top level directory for path '%s'", file_path))

  local ok, err = paths.create_dir_for_file_path(file_path)
  if err ~= nil then
    log.err(string.format("failed to create top level directory for file '%s'", file_path))
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param qoi_data any
---@param qoi_file_path string
local save_qoi_file = function(qoi_data, qoi_file_path)
  log.dbg(string.format("saving qoi data into %s", qoi_file_path))

  local qoi_f, err = io.open(qoi_file_path, "wb")
  if not qoi_f then
    log.err(string.format("failed to open '%s' for writing qoi data", qoi_file_path), err)
    os.exit(1)
  end

  local wsize2 = qoi_f:write(qoi_data)
  if not wsize2 then
    log.err(string.format("failed to write qoi data to '%s'", qoi_file_path), err)
    os.exit(1)
  end

  qoi_f:close()
end

--- -----------------------------------------------
---@param lump_f file*
---@return LumpHeader
local load_lump_file_header = function(lump_f)
  log.dbg("loading .LMP file header")

  ---@type LumpHeader
  local header = {
    Width = string.unpack("=i", lump_f:read(LumpHeader_.Width)),
    Height = string.unpack("=i", lump_f:read(LumpHeader_.Height)),
    Data = lump_f:read("a")
  }
  return header
end

--- -----------------------------------------------
---@param header LumpHeader
---@param lump_file_path string
local verify_lump_header = function(header, lump_file_path)
  log.dbg("verifying .LMP file header")

  if header.Width <= 0 or header.Height <= 0 or header.Data == nil then
    print("err: the '" .. lump_file_path .. "' file is not valid")
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param lump_file_path string
---@return integer
local get_lump_file_disk_size = function(lump_file_path)
  log.dbg("calculating .LMP file disk size")

  return paths.get_file_disk_size(lump_file_path)
end

--- -----------------------------------------------
---@param lump_file_path string
---@param lump_header LumpHeader
local print_lump_info = function(lump_file_path, lump_header)
  log.dbg("printing .LMP file information")

  local disk_size = get_lump_file_disk_size(lump_file_path)

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:               %s", lump_file_path))
  print(string.format("  ◉ Width:              %d pixels", lump_header.Width))
  print(string.format("  ◉ Height:             %d pixels", lump_header.Height))
  print(string.format("  ◉ Image Data size:    %d bytes", #lump_header.Data))
  print(string.format("  ◉ Image Size on disk: %d bytes", disk_size))
end

--- ===============================================
--- info command
--- ===============================================
---@param lump_file_path string
local cmd_info = function(lump_file_path)
  local lump_f = open_lump_file(lump_file_path)
  local lump_header = load_lump_file_header(lump_f)
  verify_lump_header(lump_header, lump_file_path)
  print_lump_info(lump_file_path, lump_header)
  lump_f:close()
end

--- ===============================================
--- decode command
--- ===============================================
---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_decode = function(lump_file_path, palette_file_path, qoi_file_path)
  local lump_f = open_lump_file(lump_file_path)
  local lump_header = load_lump_file_header(lump_f)
  verify_lump_header(lump_header, lump_file_path)
  local palette_f = open_palette_file(palette_file_path)
  local palette_size = get_palette_size(palette_f)
  verify_palette(lump_file_path, palette_size)
  local palette_data = load_palette_data(palette_f, palette_size)
  local qoi_data = convert_lump_to_qoi(lump_file_path, palette_file_path, lump_header, palette_data)
  create_toplevel_dir_for_output_file(qoi_file_path)
  save_qoi_file(qoi_data, qoi_file_path)

  palette_f:close()
  lump_f:close()
end

--- ===============================================
--- encode command
--- ===============================================
---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_encode = function(qoi_file_path, palette_file_path, lump_file_path)
  local palette_f = open_palette_file(palette_file_path)
  local palette_size = get_palette_size(palette_f)
  verify_palette(lump_file_path, palette_size)
  local palette_data = load_palette_data(palette_f, palette_size)

  local qoi_data = load_qoi_data(qoi_file_path)
  local lump_header = convert_qoi_to_lump(qoi_data, palette_data, qoi_file_path)
  verify_lump_header(lump_header, lump_file_path)

  create_toplevel_dir_for_output_file(lump_file_path)
  save_lump_file(lump_header, lump_file_path)

  palette_f:close()
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
