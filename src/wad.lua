local png = require('spng')
local log = require('libs.lua.log.log')
local utils = require('libs.lua.utils.path')
local container = require('libs.lua.utils.container')
local pprint = require('libs.lua.pprint.pprint')

--- ===============================================
--- constants
--- ===============================================

local WAD_HEADER_CODE_VALUE = "WAD2"
local WAD_HEADER_CODE_SIZE = 4
local WAD_HEADER_ITEMS_COUNT_SIZE = 4
local WAD_HEADER_OFFSET_SIZE = 4
local WAD_ITEM_HEADER_POSITION_SIZE = 4
local WAD_ITEM_HEADER_SIZE_SIZE = 4
local WAD_ITEM_HEADER_COMPRESSED_SIZE_SIZE = 4
local WAD_ITEM_HEADER_TYPE_SIZE = 1
local WAD_ITEM_HEADER_COMPRESSION_TYPE_SIZE = 1
local WAD_ITEM_HEADER_PADDINGS_SIZE = 2
local WAD_ITEM_HEADER_NAME_SIZE = 16

--- ===============================================
--- types
--- ===============================================

---@enum WadItemType
local WadItemType = {
  None    = 0,  -- not used anywher in quake engine!
  Label   = 1,  -- not used anywher in quake engine!
  Lumpy   = 64, -- not used anywher in quake engine!
  Palette = 64, -- not used anywher in quake engine!
  QTex    = 65, -- not used anywher in quake engine!
  QPic    = 66,
  Sound   = 67, -- not used anywher in quake engine!
  MipTex  = 68, -- not used anywher in quake engine!
}

--- WadHeader
---@class WadHeader
---@field Code string        (4 bytes)
---@field ItemsCount integer (4 bytes)
---@field Offset integer     (4 bytes)

--- WadItemHeader
---@class WadItemHeader
---@field Position integer        (4 bytes)
---@field Size integer            (4 bytes)
---@field CompressedSize integer  (4 bytes)
---@field Type WadItemType        (1 byte)
---@field CompressionType string  (1 byte)
---@field Paddings string         (2 bytes)
---@field Name string             (16 bytes)

--- WadItemsHeader
---@alias WadItemsHeader WadItemHeader[]


--- ===============================================
--- helper functions
--- ===============================================

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
    Code = file:read(WAD_HEADER_CODE_SIZE),
    ItemsCount = string.unpack("=i", file:read(WAD_HEADER_ITEMS_COUNT_SIZE)),
    Offset = string.unpack("=i", file:read(WAD_HEADER_OFFSET_SIZE)),
  }

  return header
end

--- -----------------------------------------------
---@param header WadHeader
local verify_wad_header = function(header)
  log.dbg("verifying .WAD file header")

  if header.Code ~= WAD_HEADER_CODE_VALUE or header.ItemsCount <= 0 or header.Offset <= 0 then
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
      Position = string.unpack("=i", file:read(WAD_ITEM_HEADER_POSITION_SIZE)),
      Size = string.unpack("=i", file:read(WAD_ITEM_HEADER_SIZE_SIZE)),
      CompressedSize = string.unpack("=i", file:read(WAD_ITEM_HEADER_COMPRESSED_SIZE_SIZE)),
      Type = string.unpack("=c1", file:read(WAD_ITEM_HEADER_TYPE_SIZE)),
      CompressionType = string.unpack("=B", file:read(WAD_ITEM_HEADER_COMPRESSION_TYPE_SIZE)),
      Paddings = file:read(WAD_ITEM_HEADER_PADDINGS_SIZE),
      Name = string.unpack("z", file:read(WAD_ITEM_HEADER_NAME_SIZE)),
    }

    items[index] = item
  end

  return items
end

--- -----------------------------------------------
---@param wit WadItemType
---@return string
local wad_item_type_to_string = function (wit)
  wit = string.byte(wit)
  if wit == WadItemType.None then return "None"
  elseif wit == WadItemType.Label then return "Label"
  elseif wit == WadItemType.Lumpy then return "Lumpy"
  elseif wit == WadItemType.Palette then return "Palette"
  elseif wit == WadItemType.QTex then return "QTex"
  elseif wit == WadItemType.QPic then return "QPic"
  elseif wit == WadItemType.Sound then return "Sound"
  elseif wit == WadItemType.MipTex then return "MipTex" end
  return "Unknown"
end

--- -----------------------------------------------
---@param wad_path string
---@return integer
local get_wad_file_disk_size = function(wad_path)
  log.dbg("calculating .WAD file disk size")

  return utils.get_file_disk_size(wad_path)
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
    print(item.Name)
  end
end

--- -----------------------------------------------
---@param p string
local create_extraction_toplevel_dir = function(p)
  log.dbg("creating top level extraction directory")

  return utils.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param dir_name string
---@param item_name string
---@return string, string
local get_extraction_file_path = function(dir_name, item_name)
  log.dbg("constracting .WAD item extraction file path")


  return utils.join_item_path(dir_name, item_name)
end

--- -----------------------------------------------
---@param p string
local create_extraction_item_dir = function(p)
  log.dbg("creating .WAD item extraction directory")

  return utils.create_dir_if_doesnt_exist(p)
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
  local data = file:read(header.Size)
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

  if not file:write(data) then
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

local function ____cmd(wad_path, out_dir)
  local wad_f, err

  repeat
    -- OPEN THE INPUT WAD FILE
    wad_f, err = io.open(wad_path, "rb")
    if not wad_f then
      print("err: failed to open '" .. wad_path .. "'. reason: " .. err)
      break
    end

    -- PREPARE THE WAD HEADER
    local wad_hdr = {
      code      = "", -- 1 byte:  wad file identifier code
      lumps_cnt = 0,  -- 4 bytes: wad file lumps count
      itbl_ofs  = 0   -- 4 bytes: wad file info table offset
    }

    wad_hdr.code = wad_f:read(4)
    wad_hdr.lumps_cnt = string.unpack("=i", wad_f:read(4))
    wad_hdr.itbl_ofs = string.unpack("=i", wad_f:read(4))

    -- VERIFY THAT WAD FILE IS VALID
    if wad_hdr.code ~= DEFS.WAD_FILE_ID and
        wad_hdr.lumps_cnt <= 0 and
        wad_hdr.itbl_ofs <= 0 then
      print("err: the '" .. wad_path .. "' file is not valid")
      break
    end

    -- MOVE THE FILE POINTER TO THE BEGINNING OF ITEMS INFO
    wad_f:seek("set", wad_hdr.itbl_ofs)

    -- READ ALL ITEMS INFO (LUMPS) IN THE WAD FILE
    local lmp_infos = {}
    for idx = 1, wad_hdr.lumps_cnt, 1 do
      local lmp_hdr = {
        pos   = 0,  -- 4  bytes:  lump file position
        size  = 0,  -- 4  bytes:  lump file size on disk
        xsize = 0,  -- 4  bytes:  lump file uncompressed size
        typ   = "", -- 1  byte:   lump file type
        cmpr  = "", -- 1  byte:   lump file compression type
        pad1  = "", -- 1  byte:   padding (not to be used)
        pad2  = "", -- 1  byte:   padding (not to be used)
        name  = ""  -- 16 bytes:  lump file name
      }

      lmp_hdr.pos = string.unpack("=i", wad_f:read(4))
      lmp_hdr.size = string.unpack("=i", wad_f:read(4))
      lmp_hdr.xsize = string.unpack("=i", wad_f:read(4))
      lmp_hdr.typ = string.unpack("=c1", wad_f:read(1)) -- cn: a fixed-sized string with n bytes
      lmp_hdr.cmpr = string.unpack("=B", wad_f:read(1)) -- an unsigned byte
      lmp_hdr.pad1 = wad_f:read(1)
      lmp_hdr.pad2 = wad_f:read(1)
      lmp_hdr.name = string.unpack("z", wad_f:read(16)) -- zero terminated c string

      -- pprint(string.format("%s # %s # %s # (%d , %d) ", lmp_hdr.name, lmp_hdr.typ, lmp_hdr.cmpr, lmp_hdr.size, lmp_hdr.xsize))
      pprint(lmp_hdr.name .. " : " .. lmp_hdr.typ .. " : " .. lmp_hdr.size)

      table.insert(lmp_infos, lmp_hdr)
    end

    -- CREATE EXTRACTION DIR
    if not path.exists(out_dir) then
      if not fs.mkdir(out_dir) then
        print("err: failed to create extraction directory: '" .. out_dir .. "'")
        break
      end
    end

    -- READ ALL LUMPS DATA
    local is_err = false
    for _, inf in pairs(lmp_infos) do
      -- CONSTRUCT PAK ITEM PATH
      local out_path = path.join(out_dir, inf.name)
      local base = path.dirname(out_path)

      -- CREATE PAK ITEM DIRECTORY IF NEEDED
      if not path.exists(base) then
        if not dir.makepath(base) then
          print("err: failed to create wad items directory '" .. base .. "'")
          is_err = true
          break
        end
      end
      if is_err then break end

      -- CREATE THE WAD ITEM FILE
      local itm_f, ierr = io.open(out_path, "wb")
      if not itm_f then
        print("err: failed to create output file '" .. out_path .. "'. reason: " .. ierr)
        is_err = true
        break
      end

      -- READ WAD ITEM DATA FROM INPUT
      wad_f:seek("set", inf.pos)
      -- !!! i'm not sure wether to use size or xsize!
      local buf = wad_f:read(inf.size) -- TODO:sepi: handle the read error
      if not buf then
        print("err: failed to read data from input wad item '" .. inf.name .. "'. reason: " .. ierr)
        itm_f:close()
        break
      end

      -- WRITE THE READ WAD ITEM DATA INTO EXTRACTED FILE
      if not itm_f:write(buf) then
        print("err: failed to write data to output file '" .. out_path .. "'. reason: " .. ierr)
        itm_f:close()
        break
      end
      itm_f:close()
    end
  until true

  -- CLEANUP
  if wad_f then wad_f:close() end
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
