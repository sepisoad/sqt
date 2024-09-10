local fs = require('lfs')
local png = require('spng')
local dir = require('libs.lua.dir.dir')
local path = require('libs.lua.dir.path')
local pprint = require('libs.lua.pprint.pprint')

local MODULE = {}
local DEFS = {
  WAD_FILE_ID = "WAD2",
  WAD_ITEM_TYPE = {
    NONE    = 0,  -- not used anywher in quake engine!
    LABEL   = 1,  -- not used anywher in quake engine!
    LUMPY   = 64, -- not used anywher in quake engine!
    PALETTE = 64, -- not used anywher in quake engine!
    QTEX    = 65, -- not used anywher in quake engine!
    QPIC    = 66,
    SOUND   = 67, -- not used anywher in quake engine!
    MIPTEX  = 68, -- not used anywher in quake engine!
  }
}

function MODULE.cmd(wad_path, out_dir)
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
      lmp_hdr.typ = wad_f:read(1)
      lmp_hdr.cmpr = wad_f:read(1)
      lmp_hdr.pad1 = wad_f:read(1)
      lmp_hdr.pad2 = wad_f:read(1)
      lmp_hdr.name = string.unpack("z", wad_f:read(16)) -- zero terminated c string

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

return MODULE
