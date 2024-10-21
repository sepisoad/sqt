local log = require('libs.lua.log.log')
local qoi = require('libs.lua.image.qoi')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')
local sqt = require('src.common')

require('libs.lua.app.types')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param file file*
---@return WadHeader
local function load_wad_file_header(file)
  log.dbg("loading .WAD file header")

  return {
    Code = read.string(file, #WadHeader._Magic),
    ItemsCount = read.integer(file),
    Offset = read.integer(file),
  }
end

--- -----------------------------------------------
---@param header WadHeader
local function verify_wad_header(header)
  log.dbg("verifying .WAD file header")

  if header.Code ~= WadHeader._Magic or
      header.ItemsCount <= 0 or
      header.Offset <= 0 then
    log.fatal(string.format(".WAD file header is not valid"))
  end
end

--- -----------------------------------------------
---@param file file*
---@param header WadHeader
local function seek_to_wad_items_header(file, header)
  log.dbg("seeking to the .WAD items header")

  file:seek("set", header.Offset)
end

--- -----------------------------------------------
---@param file file*
---@param wad_header WadHeader
---@return WadItemsHeader
local function load_wad_items_header(file, wad_header)
  log.dbg("loading .WAD items header")

  ---@type WadItemsHeader
  local items = {}

  for index = 1, wad_header.ItemsCount do
    ---@type WadItemHeader
    local item = {
      Position = read.integer(file),
      Size = read.integer(file),
      CompressedSize = read.integer(file),
      Type = read.byte(file),
      CompressionType = read.byte(file),
      Paddings = read.bytes(file, WadItemHeader._Paddings),
      Name = read.cstring(file, WadItemHeader._Name),
    }

    items[index] = item
  end

  return items
end

--- -----------------------------------------------
---@param wit WadItemType
---@return string
local function wad_item_type_to_string(wit)
  if wit == WadItemType.None then
    return "None"
  elseif wit == WadItemType.Label then
    return "Label"
  elseif wit == WadItemType.Lumpy then
    return "Lumpy"
  elseif wit == WadItemType.Palette then
    return "Palette"
  elseif wit == WadItemType.QTex then
    return "QTex"
  elseif wit == WadItemType.QPic then
    return "QPic"
  elseif wit == WadItemType.Sound then
    return "Sound"
  elseif wit == WadItemType.MipTex then
    return "MipTex"
  end
  return "Unknown"
end

--- -----------------------------------------------
---@param wad_path string
---@return integer
local function get_wad_file_disk_size(wad_path)
  log.dbg("calculating .WAD file disk size")

  return paths.get_file_disk_size(wad_path)
end

--- -----------------------------------------------
---@param wad_path string
---@param wad_header WadHeader
---@param items_header WadItemsHeader
local function print_wad_info(wad_path, wad_header, items_header)
  log.dbg("printing .WAD file information")

  local disk_size = get_wad_file_disk_size(wad_path)
  local mapping = {}
  for _, item in pairs(items_header) do
    local itype = wad_item_type_to_string(item.Type)
    if mapping[itype] == nil then
      mapping[itype] = 1
    else
      mapping[itype] = mapping[itype] + 1
    end
  end

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:            %s", wad_path))
  print(string.format("  ◉ Number of items: %d", wad_header.ItemsCount))
  print(string.format("  ◉ Size on disk:    %d bytes", disk_size))
  print("--- Items count per category -----------------------------")
  for wit, count in pairs(mapping) do
    print(string.format("  ◉ %s: %d", wit, count))
  end
end

--- -----------------------------------------------
---@param items WadItemsHeader
local function print_items_name(items)
  log.dbg("listing items from .WAD file")

  for _, item in pairs(items) do
    print(string.format("%s", item.Name))
  end
end

--- -----------------------------------------------
---@param p string
local function create_extraction_toplevel_dir(p)
  log.dbg("creating top level extraction directory")

  return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param dir_name string
---@param item_name string
---@return string, string
local function get_extraction_file_path(dir_name, item_name)
  log.dbg("constracting .WAD item extraction file path")


  return paths.join_item_path(dir_name, item_name)
end

--- -----------------------------------------------
---@param p string
local function create_extraction_item_dir(p)
  log.dbg("creating .WAD item extraction directory")

  return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param data any
---@param path string
local function extract_items_as_raw(data, path)
  log.dbg("saving .WAD data into file")

  local file <close> = xio.open(path, "wd")
  if not write.all(file, data) then
    log.fatal(string.format("failed to write .WAD item data to output file '%s'", path))
  end
end

--- -----------------------------------------------
---@param data any
---@param path string
---@param name string
local function extract_items_as_lump(data, path, name)
  log.dbg("extracting .WAD item as lump qoi file")

  local width, height, image_data = string.unpack("=I4=I4c" .. (#data - 8), data)
  local qoi_data, err = qoi.encode_indexed(image_data, QUAKE_PALETTE, width, height)
  if err then
    log.fatal(string.format("failed to decode WAD item '%s' using default palette to qoi", name), err)
  end
  sqt.save_qoi_file(qoi_data, path .. '.qoi')
end

--- -----------------------------------------------
--- TODO: in the future i need to do a file name lookup in this function and
--- check if the file name is 'CONCHARS' then perform the following actions
--- otherwise perform something elese
---@param data any
---@param path string
---@param name string
local function extract_items_as_miptex(data, path, name)
  log.dbg("extracting .WAD item as miptex qoi file")

  local width, height = 128, 128 -- TODO: this is a hardcoded value!
  local qoi_data, err = qoi.encode_indexed(data, QUAKE_PALETTE, width, height)
  if err then
    log.fatal(string.format("failed to decode WAD item '%s' using default palette to qoi", name), err)
  end
  sqt.save_qoi_file(qoi_data, path .. '.qoi')
end

--- -----------------------------------------------
---@param wad_file file*
---@param headers WadItemsHeader
---@param out_dir_path any
local function extract_items(wad_file, headers, out_dir_path)
  log.dbg("extracting items from .WAD file")

  local count = #headers
  for progress, header in pairs(headers) do
    print(string.format("%d/%d extracting '%s", progress, count, header.Name))

    wad_file:seek("set", header.Position)

    local item_path, item_dir = get_extraction_file_path(out_dir_path, header.Name)
    local item_data = read.bytes(wad_file, header.Size)

    create_extraction_item_dir(item_dir)


    if header.Type == WadItemType.QPic or header.Type == WadItemType.Lumpy then
      extract_items_as_lump(item_data, item_path, header.Name)
    elseif header.Type == WadItemType.MipTex then
      extract_items_as_miptex(item_data, item_path, header.Name)
    else
      extract_items_as_raw(item_data, item_path)
    end
  end
end

--- ===============================================
--- info command
--- ===============================================

---@param wad_file_path string
local function cmd_info(wad_file_path)
  local wad_f <close> = xio.open(wad_file_path, "rb")
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  print_wad_info(wad_file_path, wad_header, items_header)
end

--- ===============================================
--- list command
--- ===============================================

---@param wad_file_path string
local function cmd_list(wad_file_path)
  local wad_f <close> = xio.open(wad_file_path, "rb")
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  print_items_name(items_header)
end

--- ===============================================
--- extract command
--- ===============================================

---@param wad_file_path string
---@param out_dir_path string
local function cmd_extract(wad_file_path, out_dir_path)
  local wad_f <close> = xio.open(wad_file_path, "rb")
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  create_extraction_toplevel_dir(out_dir_path)
  extract_items(wad_f, items_header, out_dir_path)
end

--- ===============================================
--- create command
--- ===============================================

---@param input_dir_path string
---@param output_wad_path string
local function cmd_create(input_dir_path, output_wad_path)
  -- TODO: implement this
  log.err("this command is intentially not implemented yet!")
  log.err("  probably there are many known types of files that are allowed to be packed int a WAD file")
  log.err("  i want to learn about all of them and the get back to this command for a better understaning")
  log.err("  sorry for letting you down, but this will be fixed soon!")
  os.exit(1)
end

--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  list = cmd_list,
  extract = cmd_extract,
  create = cmd_create
}
