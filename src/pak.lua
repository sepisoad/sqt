local log = require('libs.lua.log.log')
local utils = require('libs.lua.utils.path')
local container = require('libs.lua.utils.container')

--- ===============================================
--- constants
--- ===============================================

local HEADER_ITEM_SIZE = 56 + 4 + 4 -- name + pos + len
local PAK_HEADER_SIZE = 12
local PAK_HEADER_CODE_SIZE = 4
local PAK_HEADER_OFFSET_SIZE = 4
local PAK_HEADER_LENGTH_SIZE = 4
local PAK_ITEM_HEADER_NAME_SIZE = 56
local PAK_ITEM_HEADER_POSITION_SIZE = 4
local PAK_ITEM_HEADER_LENGTH_SIZE = 4

--- ===============================================
--- types
--- ===============================================

--- PakHeader struct
---@class PakHeader
---@field Code string (4 bytes)
---@field Offset integer (4 bytes)
---@field Length integer (4 bytes)
local PakHeader = {}

--- PakItemHeader struct
---@class PakItemHeader
---@field Name string (56 bytes)
---@field Position integer (4 bytes)
---@field Length integer (4 bytes)
local PakItemHeader = {}

--- ===============================================
--- helper functions
--- ===============================================

--- -----------------------------------------------
---@param p string
---@return file*
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
---@param p string
---@return file*
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
---@param file file*
---@return PakHeader
local load_pak_file_header = function(file)
  log.dbg("loading .PAK file header")

  ---@type PakHeader
  ---@diagnostic disable-next-line: missing-fields
  local header = {}

  header.Code = file:read(PAK_HEADER_CODE_SIZE)
  header.Offset = string.unpack("=i", file:read(PAK_HEADER_OFFSET_SIZE))
  header.Length = string.unpack("=i", file:read(PAK_HEADER_LENGTH_SIZE))

  return header
end

--- -----------------------------------------------
---@param header PakHeader
local verify_pak_header = function(header)
  log.dbg("verifying .PAK file header")

  if header.Code ~= "PACK" or header.Length <= 0 or header.Offset <= 0 then
    log.err(string.format("pak file heaeder is not valid"))
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param header PakHeader
local calculate_pak_items_count = function(header)
  log.dbg("calculating the number of items in the .PAK")

  return header.Length / HEADER_ITEM_SIZE
end

--- -----------------------------------------------
---@param file file*
---@param header PakHeader
local seek_to_pak_items_header = function(file, header)
  log.dbg("seeking to the .PAK items header")

  file:seek("set", header.Offset)
end

--- -----------------------------------------------
---@param file file*
---@param header PakItemHeader
---@return any
local read_pak_item_data = function(file, header)
  log.dbg("reading .PAK item data")

  file:seek("set", header.Position)
  local data = file:read(header.Length)
  if not data then
    log.err(string.format("failed to read data from input pak item '%s'", header.Name))
    os.exit(1)
  end

  return data
end

--- -----------------------------------------------
---@param file file*
---@param items_count integer
---@return PakItemHeader
local load_pak_items_header = function(file, items_count)
  log.dbg("loading .PAK items header")

  ---@type PakItemHeader[]
  local items = {}

  for index = 1, items_count do
    ---@type PakItemHeader
    ---@diagnostic disable-next-line: missing-fields
    local item = {}

    item.Name = string.unpack("z", file:read(PAK_ITEM_HEADER_NAME_SIZE))
    item.Position = string.unpack("=i", file:read(PAK_ITEM_HEADER_POSITION_SIZE))
    item.Length = string.unpack("=i", file:read(PAK_ITEM_HEADER_LENGTH_SIZE))

    items[index] = item
  end

  return items
end

--- -----------------------------------------------
---@param p string
local create_extraction_toplevel_dir = function(p)
  log.dbg("creating top level extraction directory")

  return utils.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param p string
local create_extraction_item_dir = function(p)
  log.dbg("creating pak item extraction directory")

  return utils.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param dir_name string
---@param item_name string
---@return string, string
local get_extraction_file_path = function(dir_name, item_name)
  log.dbg("constracting pak item extraction file path")


  return utils.join_item_path(dir_name, item_name)
end

--- -----------------------------------------------
---@param file file*
---@param data any
---@param path string
local save_item_data_to_file = function(file, data, path)
  log.dbg("saving pak pak data into file")

  if not file:write(data) then
    log.err(string.format("failed to write pak item data to output file '%s'", path))
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param pak_file file*
---@param headers PakItemHeader[]
---@param out_dir_path any
local extract_items = function(pak_file, headers, out_dir_path)
  log.dbg("extracting items from .PAK file")

  local count = #headers
  for progress, header in pairs(headers) do
    log.info(string.format("%d/%d extracting '%s", progress, count, header.Name))

    local item_path, item_dir = get_extraction_file_path(out_dir_path, header.Name)
    create_extraction_item_dir(item_dir)
    local item_file = create_extracted_item_file(item_path)
    local item_data = read_pak_item_data(pak_file, header)
    save_item_data_to_file(item_file, item_data, item_path)
    item_file:close()
  end
end

--- -----------------------------------------------
---@param pak_path string
---@return integer
local get_pak_file_disk_size = function(pak_path)
  log.dbg("calculating .PAK file disk size")

  return utils.get_file_disk_size(pak_path)
end

--- -----------------------------------------------
---@param items PakItemHeader[]
local print_items_name = function(items)
  log.dbg("listing items from .PAK file")

  for _, item in pairs(items) do
    print(item.Name)
  end
end

--- -----------------------------------------------
---@param pak_path string
---@param items PakItemHeader[]
---@param items_count integer
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
  for _, item in ipairs(mapping) do
    print(string.format("  ◉ %8s: %d", item[1], item[2]))
  end
end

--- -----------------------------------------------
---@param input_dir_path string
local get_all_files_in_a_directory_recursively = function(input_dir_path)
  log.dbg(string.format("listing all files in '%s' directory before creating .PAK file from it", input_dir_path))

  return utils.list_files_in_dir(input_dir_path) or {}
end

--- -----------------------------------------------
---@param files string[]
---@return PakItemHeader[]
local create_pak_items_header_from_files = function(files)
  log.dbg("creating .PAK items header info from the files in the source directory")

  ---@type PakItemHeader[]
  local pak_items_header = {}

  local current_position = PAK_HEADER_SIZE

  for _, file in ipairs(files) do
    ---@type PakItemHeader
    local pak_item_header = {
      Name = file,
      Length = utils.get_file_disk_size(file),
      Position = current_position
    }

    table.insert(pak_items_header, pak_item_header)
    current_position = current_position + pak_item_header.Length
  end

  return pak_items_header
end

--- -----------------------------------------------
---@param items_header PakItemHeader[]
---@return PakHeader
local create_pak_header_from_pak_items_header = function(items_header)
  log.dbg(string.format("creating .PAK header info from its items header info"))

  ---@type PakHeader
  local pak_header = {
    Code = "PACK",
    Offset = PAK_HEADER_SIZE,
    Length = #items_header * HEADER_ITEM_SIZE
  }

  for _, item in ipairs(items_header) do
    pak_header.Offset = pak_header.Offset + item.Length
  end

  return pak_header
end

--- -----------------------------------------------
---@param pak_header PakHeader
---@param pak_items_header PakItemHeader[]
---@param input_dir_path string
---@param output_pak_path string
local create_pak_file = function(pak_header, pak_items_header, input_dir_path, output_pak_path)
  log.dbg(string.format("creating the actual .PAK file inti '%s'", output_pak_path))

  local pak_f, err = io.open(output_pak_path, "wb")
  if not pak_f then
    log.err(string.format("failed to open '%s' for writing .PAK data", output_pak_path), err)
    os.exit(1)
  end

  pak_f:write(pak_header.Code)
  pak_f:write(string.pack("=i", pak_header.Offset))
  pak_f:write(string.pack("=i", pak_header.Length))

  for _, pak_item_header in ipairs(pak_items_header) do
    local data = utils.read_file_data(pak_item_header.Name)
    pak_f:write(data)
  end

  for _, pak_item_header in ipairs(pak_items_header) do
    local new_name = utils.trim_path(pak_item_header.Name, input_dir_path)
    pak_f:write(string.pack("c56", new_name))
    pak_f:write(string.pack("=i", pak_item_header.Position))
    pak_f:write(string.pack("=i", pak_item_header.Length))
  end

  pak_f:close()
end

--- ===============================================
--- info command
--- ===============================================
---@param pak_file_path string
local cmd_info = function(pak_file_path)
  local pak_f = open_pak_file(pak_file_path)
  local header = load_pak_file_header(pak_f)
  verify_pak_header(header)
  local items_count = calculate_pak_items_count(header)
  seek_to_pak_items_header(pak_f, header)
  local items_header = load_pak_items_header(pak_f, items_count)
  print_pak_info(pak_file_path, items_header, items_count)
  pak_f:close()
end

--- ===============================================
--- list command
--- ===============================================
---@param pak_file_path string
local cmd_list = function(pak_file_path)
  local pak_f = open_pak_file(pak_file_path)
  local pak_header = load_pak_file_header(pak_f)
  verify_pak_header(pak_header)
  local items_count = calculate_pak_items_count(pak_header)
  seek_to_pak_items_header(pak_f, pak_header)
  local items_header = load_pak_items_header(pak_f, items_count)
  print_items_name(items_header)
  pak_f:close()
end

--- ===============================================
--- extract command
--- ===============================================
---@param pak_file_path string
---@param out_dir_path string
local cmd_extract = function(pak_file_path, out_dir_path)
  local pak_f = open_pak_file(pak_file_path)
  local pak_header = load_pak_file_header(pak_f)
  verify_pak_header(pak_header)
  local items_count = calculate_pak_items_count(pak_header)
  seek_to_pak_items_header(pak_f, pak_header)
  local items_header = load_pak_items_header(pak_f, items_count)
  create_extraction_toplevel_dir(out_dir_path)
  extract_items(pak_f, items_header, out_dir_path)
  pak_f:close()
end

--- ===============================================
--- TODO
--- ===============================================
---@param input_dir_path string
---@param output_pak_path string
local cmd_create = function(input_dir_path, output_pak_path)
  local files = get_all_files_in_a_directory_recursively(input_dir_path)
  local pak_items_header = create_pak_items_header_from_files(files)
  local pak_header = create_pak_header_from_pak_items_header(pak_items_header)
  create_pak_file(pak_header, pak_items_header, input_dir_path, output_pak_path)
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
