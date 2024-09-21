local png = require('spng')
local log = require('libs.lua.log.log')
local utils = require('libs.lua.utils.path')

--- ===============================================
--- constants
--- ===============================================
local RBG_COLOR_SIZE = 3

--- ===============================================
--- types
--- ===============================================

--- LumpHeader
---@class LumpHeader
---@field Width integer (4 bytes )
---@field Height integer (4 bytes )
---@field Data any (buffer)
local LumpHeader = {}

--- RGBColor
---@class RGBColor
---@field Red integer (1 byte unsigned, 0-255)
---@field Green integer (1 byte unsigned, 0-255)
---@field Blue integer (1 byte unsigned, 0-255)
local RGBColor = {}

--- PaletteData
---@class PaletteData
---@field Colors RGBColor[]
local PaletteData = {}

--- ===============================================
--- helper functions
--- ===============================================

--- -----------------------------------------------
---@param p string
---@return file*
local open_lump_file = function(p)
  log.dbg(string.format("openning the .LMP file from '%s'", p))

  local lump_f, err = io.open(p, "rb")
  if not lump_f then
    log.err(string.format("failed to open '%s'", p), err)
    os.exit(1)
  end

  return lump_f
end

--- -----------------------------------------------
---@param lump_f file*
---@return LumpHeader
local load_lump_file_header = function (lump_f)
  log.dbg("loading .LMP file header")

  ---@type LumpHeader
  local header = {
    Width = string.unpack("=i", lump_f:read(4)),
    Height = string.unpack("=i", lump_f:read(4)),
    Data = lump_f:read("a")
  }
  return header
end

--- -----------------------------------------------
---@param header LumpHeader
---@param lump_file_path string
local verify_lump_header = function (header, lump_file_path)
  log.dbg("verifying .LMP file header")

  if header.Width <= 0 or header.Height <= 0 or header.Data == nil then
    print("err: the '" .. lump_file_path .. "' file is not valid")
    os.exit(1)
  end
end

--- -----------------------------------------------
---@param lump_file_path string
---@return integer
local get_lump_file_disk_size = function(lump_file_path)
  log.dbg("calculating .LMP file disk size")

  return utils.get_file_disk_size(lump_file_path)
end


--- -----------------------------------------------
---@param lump_file_path string
---@param lump_header LumpHeader
local print_lump_info = function(lump_file_path, lump_header)
  log.dbg("printing .LMP file information")

  local disk_size = get_lump_file_disk_size(lump_file_path)

  print("--- Information ------------------------------------------")
  print(string.format("  ◉ Path:               %s", lump_file_path))
  print(string.format("  ◉ Width:              %d", lump_header.Width))
  print(string.format("  ◉ Height:             %d", lump_header.Height))
  print(string.format("  ◉ Image Data size:    %d", #lump_header.Data))
  print(string.format("  ◉ Image Size on disk: %d bytes", disk_size))
end

--- ===============================================
--- info command
--- ===============================================
---@param lump_file_path string
local cmd_info = function (lump_file_path)
  local lump_f = open_lump_file(lump_file_path)
  local lump_header = load_lump_file_header(lump_f)
  verify_lump_header(lump_header, lump_file_path)
  print_lump_info(lump_file_path, lump_header)
  lump_f:close()
end

--- ===============================================
--- decode command
--- ===============================================
---@param lump_file_path string
---@param palette_file_path string
---@param png_file_path string
local cmd_decode = function (lump_file_path, palette_file_path, png_file_path)

end

--- ===============================================
--- encode command
--- ===============================================
---@param png_file_path string
---@param palette_file_path string
---@param lump_file_path string
local cmd_encode = function (png_file_path, palette_file_path, lump_file_path)

end

local function ____cmd(lmp_img_path, lmp_plt_path, image_path)
  local img_lmp_f, plt_lmp_f, img_png_f, err

  repeat
    -- OPEN THE INPUT LMP IMAGE FILE
    img_lmp_f, err = io.open(lmp_img_path, "rb")
    if not img_lmp_f then
      print("err: failed to open '" .. lmp_img_path .. "'. reason: " .. err)
      break
    end

    -- PREPARE THE LMP IMAGE HEADER
    local img_hdr = { width = 0, height = 0, data = nil }

    -- READ THE IMAGE WIDTH AND MOVE 4 BYTES
    img_hdr.width = string.unpack("=i", img_lmp_f:read(4))

    -- READ THE IMAGE HEIGHT AND MOVE 8 BYTES
    img_hdr.height = string.unpack("=i", img_lmp_f:read(4))

    -- READ THE REST OF THE FILE DATA (IMAGE DATA)
    img_hdr.data = img_lmp_f:read("a")

    -- VERIFY THAT LMP IMAGE FILE IS VALID
    if img_hdr.width <= 0 or img_hdr.height <= 0 then
      print("err: the '" .. lmp_img_path .. "' file is not valid")
      break
    end

    -- OPEN THE INPUT LMP PALETTE FILE
    plt_lmp_f, err = io.open(lmp_plt_path, "rb")
    if not plt_lmp_f then
      print("err: failed to open '" .. lmp_plt_path .. "'. reason: " .. err)
      break
    end

    -- FIND THE FILE SIZE
    local plt_fsize = plt_lmp_f:seek("end", 0)

    -- VERIFY THAT LMP PALETTE FILE IS VALID
    if plt_fsize <= 0 then
      print("err: the '" .. lmp_plt_path .. "' file is not valid")
      break
    end

    -- RESET THE FILE POS
    plt_lmp_f:seek("set", 0)

    -- EXTRACT RGB PALLETE COLORS
    local plt_data = {}
    local plt_colors = plt_fsize // 3 -- (rgb = 3 * 8 => 24 bits)
    for _ = 1, plt_colors do
      local RGB = {
        r = string.unpack("=B", plt_lmp_f:read(1)),
        g = string.unpack("=B", plt_lmp_f:read(1)),
        b = string.unpack("=B", plt_lmp_f:read(1))
      }
      table.insert(plt_data, RGB)
    end

    -- CONVERT THE LMP TO PNG
    local png_data = nil
    png_data, err = png.convert(img_hdr.data, img_hdr.width, img_hdr.height, plt_data)
    if err then
      print("err: failed to convert '" .. lmp_img_path .. "' using '" .. lmp_plt_path .. "' to png: '" .. err .. "'")
    end

    -- CONSTRUCT THE OUTPUT PNG FILE PATH
    local png_dir_name = path.dirname(image_path)

    if not path.exists(png_dir_name) then
      if not dir.makepath(png_dir_name) then
        print("err: failed to create png output directory '" .. png_dir_name .. "'")
        break
      end
    end

    -- SAVE THE PNG TO FILE
    img_png_f, err = io.open(image_path, "wb")
    if not img_png_f then
      print("err: failed to open '" .. image_path .. "'. reason: " .. err)
      break
    end

    local wsize = img_png_f:write(png_data)
    if not wsize then
      print("err: failed to store converted png data to '" .. image_path .. "': '" .. err .. "'")
      break
    end
  until true

  -- CLEANUP
  if img_png_f then img_png_f:close() end
  if plt_lmp_f then plt_lmp_f:close() end
  if img_lmp_f then img_lmp_f:close() end
end



--- ===============================================
--- Module
--- ===============================================
return {
  info = cmd_info,
  decode = cmd_decode,
  encode = cmd_encode,
}
