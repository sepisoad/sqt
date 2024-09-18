local log = require('libs.lua.log.log')
local utils = require('libs.lua.utils.path')
local container = require('libs.lua.utils.container')
local pprint = require('libs.lua.pprint.pprint')

--- ===============================================
--- Definitions
local HEADER_ITEM_SIZE = 56 + 4 + 4 -- name + pos + len
local PakHeader = {
  Code   = 0,                       -- 4 bytes: pak file identifier
  Offset = 0,                       -- 4 bytes: dir offset
  Length = 0                        -- 4 bytes: dir length
}

--- ===============================================
--- helper functions
--- ===============================================

--- -----------------------------------------------
local open_pak_file = function(p)
  log.dbg(string.format("openning the .PAK file from '%s'", p))
  local pak_f, err = io.open(p, "rb")
  if not pak_f then
    log.err(string.format("failed to open '%s'", p), err)
    os.exit(1)
  end

  return pak_f
end

--- -----------------------------------------------
local create_extracted_item_file = function(p)
  log.dbg(string.format("creating .PAK item extraction file into '%s'", p))
  local item_f, err = io.open(p, "wb")
  if not item_f then
    log.err(string.format("failed to create extracted item '%s'", p), err)
    os.exit(1)
  end
  return item_f
end

--- -----------------------------------------------
local load_pak_file_header = function(file)
  log.dbg("loading .PAK file header")
  PakHeader.Code = file:read(4)
  PakHeader.Offset = string.unpack("=i", file:read(4))
  PakHeader.Length = string.unpack("=i", file:read(4))
end

--- -----------------------------------------------
local verify_pak_header = function()
  log.dbg("verifying .PAK file header")
  if PakHeader.Code ~= "PACK" or
      PakHeader.Length <= 0 or
      PakHeader.Offset <= 0 then
    log.err(string.format("pak file heaeder is not valid"))
    os.exit(1)
  end
end

--- -----------------------------------------------
local calculate_pak_items_count = function()
  log.dbg("calculating the number of items in the .PAK")
  return PakHeader.Length / HEADER_ITEM_SIZE
end

--- -----------------------------------------------
local seek_to_pak_items_header = function(file)
  log.dbg("seeking to the .PAK items header")
  file:seek("set", PakHeader.Offset)
end

--- -----------------------------------------------
local read_pak_item_data = function(file, position, length, name)
  log.dbg("reading .PAK item data")
  file:seek("set", position)
  local data = file:read(length)
  if not data then
    log.err(string.format("failed to read data from input pak item '%s'", name))
    os.exit(1)
  end
  return data
end

--- -----------------------------------------------
local load_pak_items_header = function(file, items_count)
  log.dbg("loading .PAK items header")
  local items = {}
  for index = 1, items_count do
    local item = {
      Name     = "", -- 56 bytes
      Position = 0,  -- 4 bytes
      Length   = 0   -- 4 bytes
    }
    item.Name = string.unpack("z", file:read(56))
    item.Position = string.unpack("=i", file:read(4))
    item.Length = string.unpack("=i", file:read(4))
    items[index] = item
  end

  return items
end

--- -----------------------------------------------
local create_extraction_toplevel_dir = function(p)
  log.dbg("creating top level extraction directory")
  return utils.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
local create_extraction_item_dir = function(p)
  log.dbg("creating pak item extraction directory")
  return utils.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
local get_extraction_file_path = function(dir_name, item_name)
  log.dbg("constracting pak item extraction file path")
  return utils.join_item_path(dir_name, item_name)
end

--- -----------------------------------------------
local save_item_data_to_file = function(file, data, path)
  log.dbg("saving pak pak data into file")
  if not file:write(data) then
    log.err(string.format("failed to write pak item data to output file '%s'", path))
    os.exit(1)
  end
end

--- -----------------------------------------------
local extract_items = function(pak_file, headers, out_dir_path)
  log.dbg("extracting items from .PAK file")
  local count = #headers
  for progress, header in pairs(headers) do
    log.info(string.format("%d/%d extracting '%s", progress, count, header.Name))
    local item_path, item_dir = get_extraction_file_path(out_dir_path, header.Name)
    create_extraction_item_dir(item_dir)
    local item_file = create_extracted_item_file(item_path)
    local item_data = read_pak_item_data(pak_file, header.Position, header.Length, header.Name)
    save_item_data_to_file(item_file, item_data, item_path)
    item_file:close()
  end
end

--- -----------------------------------------------
local get_pak_file_disk_size = function(pak_path)
  log.dbg("calculating .PAK file disk size")
  return utils.get_file_disk_size(pak_path)
end

--- -----------------------------------------------
local print_items_name = function(items)
  log.dbg("listing items from .PAK file")
  for _, item in pairs(items) do
    print(item.Name)
  end
end


--- -----------------------------------------------
local print_pak_info = function(pak_path, items, items_count)
  log.dbg("printing .PAK file information")

  local disk_size = get_pak_file_disk_size(pak_path)
  local names = {}
  for index, item in pairs(items) do names[index] = item.Name end
  local mapping = container.get_container_files_mapping(names)

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:            %s", pak_path))
  print(string.format("  ◉ Number of items: %d", items_count))
  print(string.format("  ◉ Size on disk:    %d bytes", disk_size))
  print("--- Items count per category -----------------------------")
  for idx, item in ipairs(mapping) do
    print(string.format("  ◉ %8s: %d", item[1], item[2]))
  end
end

--- ===============================================
--- info command
--- ===============================================
local cmd_info = function(pak_file_path)
  local pak_f = open_pak_file(pak_file_path)
  load_pak_file_header(pak_f)
  verify_pak_header()
  local items_count = calculate_pak_items_count()
  seek_to_pak_items_header(pak_f)
  local items_header = load_pak_items_header(pak_f, items_count)
  print_pak_info(pak_file_path, items_header, items_count)
end

--- ===============================================
--- list command
--- ===============================================
local cmd_list = function(pak_file_path)
  local pak_f = open_pak_file(pak_file_path)
  load_pak_file_header(pak_f)
  verify_pak_header()
  local items_count = calculate_pak_items_count()
  seek_to_pak_items_header(pak_f)
  local items_header = load_pak_items_header(pak_f, items_count)
  print_items_name(items_header)
  pak_f:close()
end

--- ===============================================
--- extract command
--- ===============================================
local cmd_extract = function(pak_file_path, out_dir_path)
  local pak_f = open_pak_file(pak_file_path)
  load_pak_file_header(pak_f)
  verify_pak_header()
  local items_count = calculate_pak_items_count()
  seek_to_pak_items_header(pak_f)
  local items_header = load_pak_items_header(pak_f, items_count)
  create_extraction_toplevel_dir(out_dir_path)
  extract_items(pak_f, items_header, out_dir_path)
  pak_f:close()
end

--- ===============================================
--- TODO
--- ===============================================
local cmd_create = function(input_dir_path, output_dir_path)
  log.err("not implemented yet!") -- TODO
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
