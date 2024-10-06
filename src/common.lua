require('libs.lua.app.types')

local log = require('libs.lua.log.log')
local qoi = require('libs.lua.image.qoi')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param path string
---@return PaletteData
local load_palette_data_from_file = function(path)
  log.dbg("loading palette data")

  local palette_f <close> = xio.open(path, "rb")

  local plt_fsize = palette_f:seek("end", 0)
  palette_f:seek("set", 0)

  if plt_fsize <= 0 then
    log.fatal("err: the palette '" .. path .. "' file is not valid")
  end

  ---@type PaletteData
  local colors = { Colors = {} }
  local rgb_size = RGBColor_.Red + RGBColor_.Green + RGBColor_.Blue
  local num_of_colors = plt_fsize // rgb_size

  for _ = 1, num_of_colors do
    ---@type RGBColor
    local RGB = {
      Red = read.byte(palette_f),
      Green = read.byte(palette_f),
      Blue = read.byte(palette_f)
    }
    table.insert(colors, RGB)
  end

  return colors
end

--- -----------------------------------------------
---@param path string
---@return LumpHeader
local load_lump_data_from_file = function(path)
  log.dbg("loading .LMP file data")

  local lump_f <close> = xio.open(path, "rb")

  ---@type LumpHeader
  local header = {
    Width = read.integer(lump_f),
    Height = read.integer(lump_f),
    Data = read.all(lump_f)
  }

  if header.Width <= 0 or header.Height <= 0 or header.Data == nil then
    log.fatal(string.format("the lump file '%s' is not valid"), path)
  end

  return header
end

--- -----------------------------------------------
---@param path string
---@return any
local load_qoi_data = function(path)
  log.dbg(string.format("openning the .qoi file from '%s'", path))

  local qoi_f <close> = xio.open(path, "rb")
  local qoi_data = read.all(qoi_f)
  if not qoi_data then
    log.fatal(string.format("failed to read the '%s' data", path))
  end

  return qoi_data
end

--- -----------------------------------------------
---@param qoi_data any
---@param qoi_file_path string
local save_qoi_file = function(qoi_data, qoi_file_path)
  log.dbg(string.format("saving qoi data into %s", qoi_file_path))

  local qoi_f <close> = xio.open(qoi_file_path, "wb")
  write.all(qoi_f, qoi_data)
end

return {
  load_palette_data_from_file = load_palette_data_from_file,
  load_lump_data_from_file = load_lump_data_from_file,
  load_qoi_data = load_qoi_data,
  save_qoi_file = save_qoi_file,
}