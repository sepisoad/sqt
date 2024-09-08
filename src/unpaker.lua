local fs = require('lfs')
local dir = require('libs.lua.dir')
local path = require('libs.lua.path')
-- local pprint = require('libs.lua.pprint')

local MODULE = {}

MODULE.defs = {
  HEADER_ITEM_SIZE = 56 + 4 + 4, -- name + pos + len
}

function MODULE.unpak()
  -- READ CMD ARGS
  local pak_file_path = arg[1]
  local extraction_path = arg[2]

  -- OPEN THE INPUT PAK FILE
  local f, err = io.open(pak_file_path, "rb")
  if not f then
    print("err: failed to open the file. reason: " .. err)
    return
  end

  -- PREPARE THE PAK HEADER
  local hdr = { code = 0, ofs = 0, len = 0 }

  -- READ THE CODE FROM FILE INTO HEADER AND MOVE 4 BYTES
  hdr.code = f:read(4)

  -- READ THE DIR OFFSET NUMBE FROM FILE INTO HEADER AND MOVE 8 BYTES
  hdr.ofs = string.unpack("i", f:read(4))

  -- READ THE DIR LEN NUMBE FROM FILE INTO HEADER AND MOVE 8 BYTES
  hdr.len = string.unpack("i", f:read(4))

  -- VERIFY THE PAK FILE IS VALID
  if hdr.code ~= "PACK" or
      hdr.len <= 0 or
      hdr.ofs <= 0 then
    print("err: the pak file is not valid")
    f:close()
    return
  end

  -- CALCAULATE THE NUMBER OF ITEMS IN THE PAK FILE
  local cnt = hdr.len / MODULE.defs.HEADER_ITEM_SIZE

  -- MOVE THE FILE POINTER TO THE BEGINNING OF ITEMS INFO
  f:seek("set", hdr.ofs)

  -- LOAD ALL ITEMS INFO INTO A LIST
  local items = {}
  for idx = 1, cnt do
    local item = { name = "", pos = 0, len = 0 }
    item.name = string.unpack("z", f:read(56))
    item.pos = string.unpack("i", f:read(4))
    item.len = string.unpack("i", f:read(4))
    items[idx] = item
  end

  -- CREATE EXTRACTION DIR
  print(extraction_path)
  if not path.exists(extraction_path) then
    if not fs.mkdir(extraction_path) then
      f:close()
      print("err: failed to create extraction directory")
      return
    end
  end

  -- LOOP OVER THE LIST AND READ THE DATA AND SAVE INTO EXTRACTION PATH
  for _, item in pairs(items) do
    -- CONSTRUCT PAK ITEM PATH
    local p = path.join(extraction_path, item.name)    
    local base = path.dirname(p)

    -- CREATE PAK ITEM DIRECTORY IF NEEDED
    if not path.exists(base) then
      if not dir.makepath(base) then
        f:close()
        print("err: failed to create pak item directory '" .. base .. "'")
        return
      end
    end

    -- CREATE THE PAK FILE
    local pf, err = io.open(p, "wb")
    if not pf then
      print("err: failed to open the file. reason: " .. err)
      return
    end

    -- READ PAK FILE DATA FROM INPUT
    f:seek("set", item.pos)
    local buf = f:read(item.len)

    -- WRITE THE READ PAK DATA INTO EXTRACTED FILE
    pf:write(buf)
    pf:close()
  end

  f:close()
end


return MODULE