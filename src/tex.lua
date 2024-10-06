require('libs.lua.app.types')
local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io')
local qoi = require('libs.lua.image.qoi')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')

local read = bits.reader
local write = bits.writer


--- -----------------------------------------------
---@param p string
---@return any
local load_qoi_data = function(p)
  log.dbg(string.format("openning the .qoi file from '%s'", p))

  local qoi_f <close> = xio.open(p, "rb")
  local qoi_data =  read.all(qoi_f)
  if not qoi_data then
    log.fatal(string.format("failed to read the '%s' data", p))
  end

  return qoi_data
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
    log.fatal("err: the palette '" .. palette_file_path .. "' file is not valid")
  end
end

--- -----------------------------------------------
---@param palette_f file*
---@param palette_size integer
---@return PaletteData
local load_palette_data = function(palette_f, palette_size)
  log.dbg("loading palette color data")

  ---@type PaletteData
  ---@diagnostic disable-next-line: missing-fields
  local colors = {}
  local num_of_colors = palette_size // RBG_COLOR_SIZE -- (rgb = 3 * 8 => 24 bits)

  for _ = 1, num_of_colors do
    ---@type RGBColor
    local RGB = {
      Red = string.unpack("=B", palette_f:read(TEX_PALETTE_COLOR_RED_SIZE)),
      Green = string.unpack("=B", palette_f:read(TEX_PALETTE_COLOR_GREEN_SIZE)),
      Blue = string.unpack("=B", palette_f:read(TEX_PALETTE_COLOR_BLUE_SIZE))
    }
    table.insert(colors, RGB)
  end
  return colors
end

--- -----------------------------------------------
---@param tex_header TexHeader
---@param palette_data PaletteData
---@return any
local convert_tex_to_qoi = function(tex_file_path, palette_file_path, tex_header, palette_data)
  log.dbg("converting tex image to qoi")

  local qoi_data = nil
  local err = nil
  qoi_data, err = qoi.encode_indexed(tex_header.Data, palette_data, tex_header.Width, tex_header.Height)
  if err then
    log.fatal(string.format("failed to decode '%s' using '%s' to qoi", tex_file_path, palette_file_path), err)
  end

  return qoi_data
end

--- -----------------------------------------------
---@param qoi_data file*
---@param palette_data any
---@param qoi_file_path string
---@param tex_name string
---@return TexHeader
local convert_qoi_to_tex = function(qoi_data, palette_data, qoi_file_path, tex_name)
  log.dbg("converting qoi image to tex")

  local tex_data, tex_width, tex_height = qoi.decode_indexed(qoi_data, palette_data)
  if not tex_data then
    log.fatal(string.format("failed to convert qoi data to tex data from '%s'", qoi_file_path))
  end

  ---@type TexHeader
  local tex_header = {
    Name = tex_name,
    Width = tex_width,
    Height = tex_height,
    Data = tex_data
  }

  return tex_header
end

--- -----------------------------------------------
---@param tex_header TexHeader
---@param tex_file_path string
local save_tex_file = function(tex_header, tex_file_path)
  log.dbg(string.format("saving LMP data into %s", tex_file_path))

  local tex_f <close> = xio.open(tex_file_path, "wb")
  tex_f:write(string.pack("=i", tex_header.Width))
  tex_f:write(string.pack("=i", tex_header.Height))
  tex_f:write(tex_header.Data)
end

--- -----------------------------------------------
---@param file_path string
local create_toplevel_dir_for_output_file = function(file_path)
  log.dbg(string.format("creating top level directory for path '%s'", file_path))

  local _, err = paths.create_dir_for_file_path(file_path)
  if err ~= nil then
    log.fatal(string.format("failed to create top level directory for file '%s'", file_path))
  end
end

--- -----------------------------------------------
---@param qoi_data any
---@param qoi_file_path string
local save_qoi_file = function(qoi_data, qoi_file_path)
  log.dbg(string.format("saving qoi data into %s", qoi_file_path))

  local qoi_f <close> = xio.open(qoi_file_path, "wb")
  local wsize = bits.w_all(qoi_f, qoi_data)
  if not wsize then
    log.fatal(string.format("failed to write qoi data to '%s'", qoi_file_path))
  end
end

--- -----------------------------------------------
---@param tex_f file*
---@return TexHeader
local load_tex_file_header = function(tex_f)
  log.dbg("loading .TEX file header")

  ---@type TexHeader
  local header = {
    Name = read.cstring(tex_f, TexHeader._Name),
    Width = read.integer(tex_f),
    Height = read.integer(tex_f),
    Data = read.all(tex_f)
  }
  return header
end

--- -----------------------------------------------
---@param header TexHeader
---@param tex_file_path string
local verify_tex_header = function(header, tex_file_path)
  log.dbg("verifying .TEX file header")

  if header.Name == nil or
     header.Name == "" or
     header.Width <= 0 or
     header.Height <= 0 or
     header.Data == nil then
    log.fatal("the '" .. tex_file_path .. "' file is not valid")
  end
end

--- -----------------------------------------------
---@param tex_file_path string
---@return integer
local get_tex_file_disk_size = function(tex_file_path)
  log.dbg("calculating .TEX file disk size")

  return paths.get_file_disk_size(tex_file_path)
end

--- -----------------------------------------------
---@param tex_file_path string
---@param tex_header TexHeader
local print_tex_info = function(tex_file_path, tex_header)
  log.dbg("printing .TEX file information")

  local disk_size = get_tex_file_disk_size(tex_file_path)

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:               %s", tex_file_path))
  print(string.format("  ◉ Name:               %s", tex_header.Name))
  print(string.format("  ◉ Width:              %d pixels", tex_header.Width))
  print(string.format("  ◉ Height:             %d pixels", tex_header.Height))
  print(string.format("  ◉ Image Data size:    %d bytes", #tex_header.Data))
  print(string.format("  ◉ Image Size on disk: %d bytes", disk_size))
end

--- ===============================================
--- info command
--- ===============================================
---@param tex_file_path string
local cmd_info = function(tex_file_path)
  local tex_f = xio.open(tex_file_path, "rb")
  local tex_header = load_tex_file_header(tex_f)
  verify_tex_header(tex_header, tex_file_path)
  print_tex_info(tex_file_path, tex_header)
  tex_f:close()
end

--- ===============================================
--- decode command
--- ===============================================
---@param tex_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_decode = function(tex_file_path, palette_file_path, qoi_file_path)
  local tex_f <close> = xio.open(tex_file_path, "rb")
  local tex_header = load_tex_file_header(tex_f)
  verify_tex_header(tex_header, tex_file_path)
  local palette_f <close> = xio.open(palette_file_path, "rb")
  local palette_size = get_palette_size(palette_f)
  verify_palette(tex_file_path, palette_size)
  local palette_data = load_palette_data(palette_f, palette_size)
  local qoi_data = convert_tex_to_qoi(tex_file_path, palette_file_path, tex_header, palette_data)
  create_toplevel_dir_for_output_file(qoi_file_path)
  save_qoi_file(qoi_data, qoi_file_path)
end

--- ===============================================
--- encode command
--- ===============================================
---@param tex_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_encode = function(qoi_file_path, palette_file_path, tex_file_path)
  local palette_f <close> = xio.open(palette_file_path, "rb")
  local palette_size = get_palette_size(palette_f)
  verify_palette(tex_file_path, palette_size)
  local palette_data = load_palette_data(palette_f, palette_size)

  local qoi_data = load_qoi_data(qoi_file_path)
  local tex_header = convert_qoi_to_tex(qoi_data, palette_data, qoi_file_path, "TODO") --TODO:sepi
  verify_tex_header(tex_header, tex_file_path)

  create_toplevel_dir_for_output_file(tex_file_path)
  save_tex_file(tex_header, tex_file_path)
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
