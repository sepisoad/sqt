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
local function load_lump_data_from_file (path)
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
---@param header LumpHeader
---@param palette PaletteData
---@return any
local function save_png_file (lump_path, header, palette)
  log.dbg("converting lump image to png")

  sqt.save_png_file(header.Data, palette, header.Width, header.Height, lump_path)
end


--- -----------------------------------------------
---@param file_path string
local function create_toplevel_dir_for_output_file (file_path)
  log.dbg(string.format("creating top level directory for path '%s'", file_path))

  local _, err = paths.create_dir_for_file_path(file_path)
  if err ~= nil then
    log.fatal(string.format("failed to create top level directory for file '%s'", file_path))
  end
end

--- -----------------------------------------------
---@param lump_file_path string
---@param lump_header LumpHeader
local function print_lump_info (lump_file_path, lump_header)
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

---@param lump_file_path string
local function cmd_info (lump_file_path)
  local lump_header = load_lump_data_from_file(lump_file_path)
  print_lump_info(lump_file_path, lump_header)
end

--- ===============================================
--- decode command
--- ===============================================

---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local function cmd_decode (lump_file_path, palette_file_path, qoi_file_path)
  local lump_header = load_lump_data_from_file(lump_file_path)
  local palette_data = sqt.load_palette_data_from_path(palette_file_path)
  create_toplevel_dir_for_output_file(qoi_file_path)
  save_png_file(lump_file_path, lump_header, palette_data)
end

--- ===============================================
--- encode command
--- ===============================================

---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local function cmd_encode (qoi_file_path, palette_file_path, lump_file_path)
  -- local palette_data = sqt.load_palette_data_from_path(palette_file_path)
  -- local qoi_data = sqt.load_qoi_data(qoi_file_path)
  -- local lump_header = convert_qoi_to_lump(qoi_data, palette_data, qoi_file_path)
  -- create_toplevel_dir_for_output_file(lump_file_path)
  -- save_lump_file(lump_header, lump_file_path)
  log.fatal("NEED TO UPDATE!")
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
