require('libs.lua.app.types')

local stb = require('stb')
local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')

local read = bits.reader
local write = bits.writer
--- -----------------------------------------------
---@param path string
local function create_parent_dir(path)
  log.dbg(string.format("creating top level directory for path '%s'", path))

  local _, err = paths.create_dir_for_file_path(path)
  if err ~= nil then
    log.fatal(string.format("failed to create top level directory for file '%s'", path))
  end
end

--- -----------------------------------------------
---@param palette_f file*
---@param position integer
---@param size integer
---@return PaletteData
local function load_palette_from_file(palette_f, position, size)
  log.dbg("loading palette data from file")

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
local function load_palette_from_path(path)
  log.dbg("loading palette data from path")

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
---@param from string|file*
---@param position integer|nil
---@param size integer|nil
---@return PaletteData
local function load_palette(from, position, size)
  if type(from) == 'string' then
    return load_palette_from_path(from)
  else
    assert(position ~= nil)
    assert(size ~= nil)
    return load_palette_from_file(from, position, size)
  end
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

--- -----------------------------------------------
---@param path string
---@param palette PaletteData
---@return table, number, number 
local function load_png_file(path, palette)
  log.dbg(string.format("loading png data from %s", path))

  local ok, data, width, height = pcall(stb.decode_paletted_png, palette, path)
  if not ok then
    log.err(data)
    return {}, 0, 0 -- TODO: wtf is wrong with this?
  end

  return data, width, height
end

--- -----------------------------------------------
--- MODULE
--- -----------------------------------------------
return {
  create_parent_dir = create_parent_dir,
  load_palette = load_palette,
  save_png_file = save_png_file,
  load_png_file = load_png_file,
}
