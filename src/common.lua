require('libs.lua.app.types')

local stb = require('stb')
local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param palette_f file*
---@param position integer
---@param size integer
---@return PaletteData
local function load_palette_data_from_file(palette_f, position, size)
  log.dbg("loading palette data")

  palette_f:seek("set", position)

  ---@type PaletteData
  local colors = { Colors = {} }
  local num_of_colors = size // RGBColor._Size

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
---@return PaletteData
local function load_palette_data_from_path(path)
  log.dbg("loading palette data")

  local palette_f <close> = xio.open(path, "rb")

  local plt_fsize = palette_f:seek("end", 0)
  palette_f:seek("set", 0)

  if plt_fsize <= 0 then
    log.fatal("err: the palette '" .. path .. "' file is not valid")
  end

  ---@type PaletteData
  local colors = { Colors = {} }
  local num_of_colors = plt_fsize // RGBColor._Size

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
---@return any
local function load_qoi_data(path)
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
local function save_qoi_file(qoi_data, qoi_file_path)
  log.dbg(string.format("saving qoi data into %s", qoi_file_path))

  local qoi_f <close> = xio.open(qoi_file_path, "wb")
  write.all(qoi_f, qoi_data)
end

--- -----------------------------------------------
---@param data string
---@param palette table
---@param width number
---@param height number
---@param path string
local function save_png_file(data, palette, width, height, path)
  log.dbg(string.format("saving png data into %s", path))

  local pixels = {}
  for i = 1, #data, 1 do
    pixels[i] = string.byte(data, i)
  end

  local ok, err = pcall(stb.encode_paletted_png, path, palette, pixels, width, height)
  if not ok then
    log.err(err)
  end
end

return {
  load_palette_data_from_file = load_palette_data_from_file,
  load_palette_data_from_path = load_palette_data_from_path,
  load_qoi_data = load_qoi_data,
  save_qoi_file = save_qoi_file,
  save_png_file = save_png_file,
}
