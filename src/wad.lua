require('libs.lua.app.types')
local log = require('libs.lua.log.log')
local paths = require('libs.lua.utils.paths')
local bits = require('libs.lua.utils.bits')

--- -----------------------------------------------
---@param p string
---@return file*
local open_wad_file = function(p)
  log.dbg(string.format("openning the .WAD file from '%s'", p))

  local wad_f, err = io.open(p, "rb")
  if not wad_f then
    log.err(string.format("failed to open '%s'", p), err)
    os.exit(1)
  end

  return wad_f
end

--- -----------------------------------------------
---@param file file*
---@return WadHeader
local load_wad_file_header = function(file)
  log.dbg("loading .WAD file header")

  ---@type WadHeader
  local header = {
    Code = bits.r_buf(file, WadHeader_.Code),
    ItemsCount = bits.r_i32(file, WadHeader_.ItemsCount),
    Offset = bits.r_i32(file, WadHeader_.Offset),
  }

  return header
end

--- -----------------------------------------------
---@param header WadHeader
local verify_wad_header = function(header)
  log.dbg("verifying .WAD file header")

  if header.Code ~= WadHeader_.CODE or
      header.ItemsCount <= 0 or
      header.Offset <= 0 then
    log.err(string.format(".WAD file header is not valid"))
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param file file*
---@param header WadHeader
local seek_to_wad_items_header = function(file, header)
  log.dbg("seeking to the .WAD items header")

  file:seek("set", header.Offset)
end

--- -----------------------------------------------
---@param file file*
---@param wad_header WadHeader
---@return WadItemsHeader
local load_wad_items_header = function(file, wad_header)
  log.dbg("loading .WAD items header")

  ---@type WadItemsHeader
  local items = {}

  for index = 1, wad_header.ItemsCount do
    ---@type WadItemHeader
    local item = {
      Position = bits.r_i32(file, WadItemHeader_.Position),
      Size = bits.r_i32(file, WadItemHeader_.Size),
      CompressedSize = bits.r_i32(file, WadItemHeader_.CompressedSize),
      ---@diagnostic disable-next-line: assign-type-mismatch
      Type = bits.r_chrs(file, WadItemHeader_.Type),
      ---@diagnostic disable-next-line: assign-type-mismatch
      CompressionType = bits.r_u8(file, WadItemHeader_.CompressionType),
      Paddings = bits.r_buf(file, WadItemHeader_.Paddings),
      Name = bits.r_cstr(file, WadItemHeader_.Name),
    }

    items[index] = item
  end

  return items
end

--- -----------------------------------------------
---@param wit WadItemType
---@return string
local wad_item_type_to_string = function(wit)
  wit = string.byte(wit)
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
local get_wad_file_disk_size = function(wad_path)
  log.dbg("calculating .WAD file disk size")

  return paths.get_file_disk_size(wad_path)
end

--- -----------------------------------------------
---@param wad_path string
---@param wad_header WadHeader
---@param items_header WadItemsHeader
local print_wad_info = function(wad_path, wad_header, items_header)
  log.dbg("printing .WAD file information")

  local disk_size = get_wad_file_disk_size(wad_path)
  local mapping = {}
  for _, item in pairs(items_header) do
    if mapping[item.Type] == nil then
      mapping[item.Type] = 1
    else
      mapping[item.Type] = mapping[item.Type] + 1 or 1
    end
  end

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:            %s", wad_path))
  print(string.format("  ◉ Number of items: %d", wad_header.ItemsCount))
  print(string.format("  ◉ Size on disk:    %d bytes", disk_size))
  print("--- Items count per category -----------------------------")
  for wit, count in pairs(mapping) do
    print(string.format("  ◉ %8s: %d", wad_item_type_to_string(wit), count))
  end
end

--- -----------------------------------------------
---@param items WadItemsHeader
local print_items_name = function(items)
  log.dbg("listing items from .WAD file")

  for _, item in pairs(items) do
    print(string.format("%s",item.Name))
  end
end

--- -----------------------------------------------
---@param p string
local create_extraction_toplevel_dir = function(p)
  log.dbg("creating top level extraction directory")

  return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param dir_name string
---@param item_name string
---@return string, string
local get_extraction_file_path = function(dir_name, item_name)
  log.dbg("constracting .WAD item extraction file path")


  return paths.join_item_path(dir_name, item_name)
end

--- -----------------------------------------------
---@param p string
local create_extraction_item_dir = function(p)
  log.dbg("creating .WAD item extraction directory")

  return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param p string
---@return file*
local create_extracted_item_file = function(p)
  log.dbg(string.format("creating .WAD item extraction file into '%s'", p))

  local item_f, err = io.open(p, "wb")
  if not item_f then
    log.err(string.format("failed to create extracted item '%s'", p), err)
    os.exit(1)
  end
  return item_f
end

--- -----------------------------------------------
---@param file file*
---@param header WadItemHeader
---@return any
local read_wad_item_data = function(file, header)
  log.dbg("reading .WAD item data")

  file:seek("set", header.Position)
  local data = bits.r_buf(file, header.Size)
  if not data then
    log.err(string.format("failed to read data from input .WAD item '%s'", header.Name))
    os.exit(1)
  end

  return data
end

--- -----------------------------------------------
---@param file file*
---@param data any
---@param path string
local save_item_data_to_file = function(file, data, path)
  log.dbg("saving .WAD data into file")

  if not bits.w_all(file, data) then
    log.err(string.format("failed to write .WAD item data to output file '%s'", path))
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param wad_file file*
---@param headers WadItemsHeader
---@param out_dir_path any
local extract_items = function(wad_file, headers, out_dir_path)
  log.dbg("extracting items from .WAD file")

  local count = #headers
  for progress, header in pairs(headers) do
    print(string.format("%d/%d extracting '%s", progress, count, header.Name))

    local item_path, item_dir = get_extraction_file_path(out_dir_path, header.Name)
    create_extraction_item_dir(item_dir)
    local item_file = create_extracted_item_file(item_path)
    local item_data = read_wad_item_data(wad_file, header)
    save_item_data_to_file(item_file, item_data, item_path)
    item_file:close()
  end
end

--- ===============================================
--- info command
--- ===============================================
---@param wad_file_path string
local cmd_info = function(wad_file_path)
  local wad_f = open_wad_file(wad_file_path)
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  print_wad_info(wad_file_path, wad_header, items_header)
  wad_f:close()
end

--- ===============================================
--- list command
--- ===============================================
---@param wad_file_path string
local cmd_list = function(wad_file_path)
  local wad_f = open_wad_file(wad_file_path)
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  print_items_name(items_header)
  wad_f:close()
end

--- ===============================================
--- extract command
--- ===============================================
---@param wad_file_path string
---@param out_dir_path string
local cmd_extract = function(wad_file_path, out_dir_path)
  local wad_f = open_wad_file(wad_file_path)
  local wad_header = load_wad_file_header(wad_f)
  verify_wad_header(wad_header)
  seek_to_wad_items_header(wad_f, wad_header)
  local items_header = load_wad_items_header(wad_f, wad_header)
  create_extraction_toplevel_dir(out_dir_path)
  extract_items(wad_f, items_header, out_dir_path)
  wad_f:close()
end

--- ===============================================
--- create command
--- ===============================================
---@param input_dir_path string
---@param output_wad_path string
local cmd_create = function(input_dir_path, output_wad_path)
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
