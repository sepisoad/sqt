--- ===============================================
--- WadItemType
--- ===============================================

---@enum WadItemType
WadItemType = {
  None    = 0,  -- not used anywher in quake engine!
  Label   = 1,  -- not used anywher in quake engine!
  Lumpy   = 64, -- not used anywher in quake engine!
  Palette = 64, -- not used anywher in quake engine!
  QTex    = 65, -- not used anywher in quake engine!
  QPic    = 66,
  Sound   = 67, -- not used anywher in quake engine!
  MipTex  = 68, -- not used anywher in quake engine!
}

--- ===============================================
--- WadHeader
--- ===============================================

--- WadHeader
---@class WadHeader
---@field Code string        (4 bytes)
---@field ItemsCount integer (4 bytes)
---@field Offset integer     (4 bytes)
WadHeader = {}

---@enum WadHeader_
WadHeader_ = {
  CODE = "WAD2",
  Code = 4,
  ItemsCount = 4,
  Offset = 4,
}

--- ===============================================
--- WadItem(s)Header
--- ===============================================

--- WadItemHeader
---@class WadItemHeader
---@field Position integer
---@field Size integer
---@field CompressedSize integer
---@field Type WadItemType
---@field CompressionType string
---@field Paddings string
---@field Name string
WadItemHeader = {}

---@alias WadItemsHeader WadItemHeader[]

---@enum WadItemHeader_
WadItemHeader_ = {
  Position = 4,
  Size = 4,
  CompressedSize = 4,
  Type = 1,
  CompressionType = 1,
  Paddings = 2,
  Name = 16,
}

--- ===============================================
--- TexHeader
--- ===============================================

--- TexHeader
---@class TexHeader
---@field Name string
---@field Width integer
---@field Height integer
---@field Data any
TexHeader = {}

---@enum TexHeader_
TexHeader_ = {
  Name = 16,
  Width = 4,
  Height = 4,
  Data = "*"
}

--- ===============================================
--- TexHeader
--- ===============================================

--- PakHeader
---@class PakHeader
---@field Code string (4 bytes)
---@field Offset integer (4 bytes)
---@field Length integer (4 bytes)
PakHeader = {}

---@enum PakHeader_
PakHeader_ = {
  CODE = "PACK",
  Code = 4,
  Offset = 4,
  Length = 4,
}

--- ===============================================
--- PakItemHeader
--- ===============================================

--- PakItemHeader
---@class PakItemHeader
---@field Name string
---@field Position integer
---@field Length integer
PakItemHeader = {}

---@alias PakItemsHeader PakItemHeader[]

---@enum PakItemHeader_
PakItemHeader_ = {
  Name = 56,
  Position = 4,
  Length = 4,
}


--- ===============================================
--- PakItemHeader
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