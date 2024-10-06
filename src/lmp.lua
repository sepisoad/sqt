require('libs.lua.app.types')
local log = require('libs.lua.log.log')
local qoi = require('libs.lua.image.qoi')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')
local sqt = require('src.common')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param p string
---@return any
local load_qoi_data = function(p)
  log.dbg(string.format("openning the .qoi file from '%s'", p))

  local qoi_f <close> = xio.open(p, "rb")
  local qoi_data = read.all(qoi_f)
  if not qoi_data then
    log.fatal(string.format("failed to read the '%s' data", p))
  end

  return qoi_data
end

--- -----------------------------------------------
---@param lump_header LumpHeader
---@param palette_data PaletteData
---@return any
local convert_lump_to_qoi = function(lump_file_path, palette_file_path, lump_header, palette_data)
  log.dbg("converting lump image to qoi")

  local qoi_data, err = qoi.encode_indexed(lump_header.Data, palette_data, lump_header.Width, lump_header.Height)
  if err then
    log.fatal(string.format("failed to decode '%s' using '%s' to qoi", lump_file_path, palette_file_path), err)
  end
  return qoi_data
end

--- -----------------------------------------------
---@param qoi_data file*
---@param palette_data any
---@param qoi_path string
---@return LumpHeader
local convert_qoi_to_lump = function(qoi_data, palette_data, qoi_path)
  log.dbg("converting qoi image to lump")

  local data, width, height = qoi.decode_indexed(qoi_data, palette_data)
  if not data then
    log.fatal(string.format("failed to convert qoi data to lump data from '%s'", qoi_path))
  end
  return { Width = width, Height = height, Data = data }
end

--- -----------------------------------------------
---@param header LumpHeader
---@param path string
local save_lump_file = function(header, path)
  log.dbg(string.format("saving LMP data into %s", path))

  local lump_f <close> = xio.open(path, "wb")
  if not lump_f then
    log.fatal(string.format("failed to open '%s' for writing LMP data", path))
  end

  write.integer(lump_f, header.Width)
  write.integer(lump_f, header.Height)
  write.all(lump_f, header.Data)
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
  write.all(qoi_f, qoi_data)
end

--- -----------------------------------------------
---@param lump_f file*
---@return LumpHeader
local load_lump_file_header = function(lump_f)
  log.dbg("loading .LMP file header")

  return {
    Width = read.integer(lump_f),
    Height = read.integer(lump_f),
    Data = read.all(lump_f)
  }
end

--- -----------------------------------------------
---@param lump_file_path string
---@param lump_header LumpHeader
local print_lump_info = function(lump_file_path, lump_header)
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
local cmd_info = function(lump_file_path)
  local lump_header = sqt.load_lump_data_from_file(lump_file_path)
  print_lump_info(lump_file_path, lump_header)
end

--- ===============================================
--- decode command
--- ===============================================
---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_decode = function(lump_file_path, palette_file_path, qoi_file_path)
  local lump_header = sqt.load_lump_data_from_file(lump_file_path)
  print_lump_info(lump_file_path, lump_header)
  local palette_data = sqt.load_palette_data_from_file(palette_file_path)
  local qoi_data = convert_lump_to_qoi(lump_file_path, palette_file_path, lump_header, palette_data)
  create_toplevel_dir_for_output_file(qoi_file_path)
  save_qoi_file(qoi_data, qoi_file_path)
end

--- ===============================================
--- encode command
--- ===============================================
---@param lump_file_path string
---@param palette_file_path string
---@param qoi_file_path string
local cmd_encode = function(qoi_file_path, palette_file_path, lump_file_path)
  local palette_f <close> = xio.open(palette_file_path, "rb")
  local palette_data = sqt.load_palette_data_from_file(palette_file_path)
  local qoi_data = load_qoi_data(qoi_file_path)
  local lump_header = convert_qoi_to_lump(qoi_data, palette_data, qoi_file_path)
  create_toplevel_dir_for_output_file(lump_file_path)
  save_lump_file(lump_header, lump_file_path)
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
