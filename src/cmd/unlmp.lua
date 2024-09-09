local fs = require('lfs')
local png = require('spng')
local dir = require('libs.lua.dir.dir')
local path = require('libs.lua.dir.path')
local pprint = require('libs.lua.pprint.pprint')

local MODULE = {}

MODULE.defs = {
  -- HEADER_ITEM_SIZE = 56 + 4 + 4, -- name + pos + len
}

-- unlmp command that converts a .lmp file into an image
-- @param lmp_img_path: is the input .lmp image file
-- @param lmp_plt_path: is the input .lmp palette file (it's needed to encode the colors)
-- this function is a command and does not return any value,
-- it either get the job done or fails
function MODULE.cmd(lmp_img_path, lmp_plt_path, image_path)
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
      print("err: failed to convert '" .. lmp_img_path .. "' using '" .. lmp_plt_path ..  "' to png: '" .. err .. "'")
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

    break
  until false

  -- CLEANUP
  if img_png_f then img_png_f:close() end
  if plt_lmp_f then plt_lmp_f:close() end
  if img_lmp_f then img_lmp_f:close() end
end

return MODULE
