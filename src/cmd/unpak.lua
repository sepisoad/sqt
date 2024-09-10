local fs = require('lfs')
local dir = require('libs.lua.dir.dir')
local path = require('libs.lua.dir.path')

local MODULE = {}
local DEFS = {
  HEADER_ITEM_SIZE = 56 + 4 + 4, -- name + pos + len
}

function MODULE.cmd(pak_path, out_dir)
  local pak_f, err

  repeat
    -- OPEN THE INPUT PAK FILE
    pak_f, err = io.open(pak_path, "rb")
    if not pak_f then
      print("err: failed to open '" .. pak_path .. "'. reason: " .. err)
      break
    end

    -- PREPARE THE PAK HEADER
    local hdr = {
      code = 0, -- 4 bytes: pak file identifier
      ofs  = 0, -- 4 bytes: dir offset
      len  = 0  -- 4 bytes: dir length
    }

    hdr.code = pak_f:read(4)
    hdr.ofs = string.unpack("=i", pak_f:read(4))
    hdr.len = string.unpack("=i", pak_f:read(4))

    -- VERIFY THE PAK FILE IS VALID
    if hdr.code ~= "PACK" or
        hdr.len <= 0 or
        hdr.ofs <= 0 then
      print("err: the '" .. pak_path .. "' file is not valid")
      break
    end

    -- CALCAULATE THE NUMBER OF ITEMS IN THE PAK FILE
    local cnt = hdr.len / DEFS.HEADER_ITEM_SIZE

    -- MOVE THE FILE POINTER TO THE BEGINNING OF ITEMS INFO
    pak_f:seek("set", hdr.ofs)

    -- LOAD ALL ITEMS INFO INTO A LIST
    local items = {}
    for idx = 1, cnt do
      local item = { name = "", pos = 0, len = 0 }
      item.name = string.unpack("z", pak_f:read(56))
      item.pos = string.unpack("=i", pak_f:read(4))
      item.len = string.unpack("=i", pak_f:read(4))
      items[idx] = item
    end

    -- CREATE EXTRACTION DIR
    if not path.exists(out_dir) then
      if not fs.mkdir(out_dir) then
        print("err: failed to create extraction directory: '" .. out_dir .. "'")
        break
      end
    end

    -- LOOP OVER THE LIST AND READ THE DATA AND SAVE INTO EXTRACTION PATH
    local is_err = false
    for _, item in pairs(items) do
      -- CONSTRUCT PAK ITEM PATH
      local out_path = path.join(out_dir, item.name)
      local base = path.dirname(out_path)

      -- CREATE PAK ITEM DIRECTORY IF NEEDED
      if not path.exists(base) then
        if not dir.makepath(base) then
          print("err: failed to create pak items directory '" .. base .. "'")
          is_err = true
          break
        end
      end
      if is_err then break end

      -- CREATE THE PAK FILE
      local itm_f, ierr = io.open(out_path, "wb")
      if not itm_f then
        print("err: failed to create output file '" .. out_path .. "'. reason: " .. ierr)
        is_err = true
        break
      end

      -- READ PAK FILE DATA FROM INPUT
      pak_f:seek("set", item.pos)
      local buf = pak_f:read(item.len)
      if not buf then
        print("err: failed to read data from input pak item '" .. item.name .. "'. reason: " .. ierr)
        itm_f:close()
        break
      end

      -- WRITE THE READ PAK DATA INTO EXTRACTED FILE
      if not itm_f:write(buf) then
        print("err: failed to write data to output file '" .. out_path .. "'. reason: " .. ierr)
        itm_f:close()
        break
      end
      itm_f:close()
    end
  until true

  -- CLEANUP
  if pak_f then pak_f:close() end
end

return MODULE
