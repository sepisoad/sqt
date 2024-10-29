local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')
local sqt = require('src.common')

require('libs.lua.app.types')
require('libs.lua.app.data')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param path string
---@return LumpHeader
local function load_lump(path)
  log.dbg("loading .LMP file data")

  local lump_f <close> = xio.open(path, "rb")

  ---@type LumpHeader
  local header = {
    Width = read.integer(lump_f),
    Height = read.integer(lump_f),
    Data = read.all(lump_f)
  }

  if header.Width <= 0 or header.Height <= 0 or header.Data == nil then
    log.err(string.format("the lump file '%s' is not valid", path))
  end

  return header
end

--- -----------------------------------------------
---@param path string
---@param data table
---@param width number
---@param height number
local function save_lump(path, data, width, height)
  log.dbg("saving .LMP file data")

  local lump_f <close> = xio.open(path, "wb")

  write.integer(lump_f, width)
  write.integer(lump_f, height)
  write.all(lump_f, data)
end

--- -----------------------------------------------
---@param lump_file_path string
---@param lump_header LumpHeader
local function print_lump_info(lump_file_path, lump_header)
  log.dbg("printing .LMP file information")

  local disk_size = paths.get_file_disk_size(lump_file_path)

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

---@param lump_path string
local function cmd_info(lump_path)
  local lump_header = load_lump(lump_path)
  print_lump_info(lump_path, lump_header)
end

--- ===============================================
--- decode command
--- ===============================================

---@param lump_path string
---@param palette_file_path string
---@param png_path string
local function cmd_decode(lump_path, palette_file_path, png_path)
  local header = load_lump(lump_path)
  local palette = sqt.load_palette(palette_file_path)
  sqt.create_parent_dir(png_path)
  sqt.save_png_file(header.Data, palette, header.Width, header.Height, png_path)
end

--- ===============================================
--- encode command
--- ===============================================

---@param lump_path string
---@param palette_path string
---@param png_path string
local function cmd_encode(png_path, palette_path, lump_path)
  local palette_data = sqt.load_palette(palette_path)
  sqt.create_parent_dir(lump_path)
  local data, width, height = sqt.load_png_file(png_path, palette_data)
  save_lump(lump_path, data, width, height)
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
