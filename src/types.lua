local ffi = require("ffi")

-- ===============================================
-- WadItemType
-- ===============================================

---@alias WadItemType integer
---| 0 # WadItemType_None
---| 1 # WadItemType_Label
---| 64 # WadItemType_Lumpy
---| 64 # WadItemType_Palette
---| 65 # WadItemType_QTex
---| 66 # WadItemType_QPic
---| 67 # WadItemType_Sound
---| 68 # WadItemType_MipTex

ffi.cdef [[
  typedef enum {
    WadItemType_None = 0,
    WadItemType_Label = 1,
    WadItemType_Lumpy = 64,
    WadItemType_Palette = 64,
    WadItemType_QTex = 65,
    WadItemType_QPic = 66,
    WadItemType_Sound = 67,
    WadItemType_MipTex = 68
  } WadItemType;
]]

-- ===============================================
-- WadHeader
-- ===============================================

---@class WadHeader
---@field Code string        -- 4 bytes
---@field ItemsCount integer -- 4 bytes
---@field Offset integer     -- 4 bytes
ffi.cdef [[
  typedef struct {
    char Code[4];        // 4 bytes
    int32_t ItemsCount;  // 4 bytes (integer)
    int32_t Offset;      // 4 bytes (integer)
  } WadHeader;
]]

---@type string
WAD_MAGIC = "WAD2"

-- ===============================================
-- WadItemHeader
-- ===============================================

---@class WadItemHeader
---@field Position integer         -- 4 bytes
---@field Size integer             -- 4 bytes
---@field CompressedSize integer   -- 4 bytes
---@field Type integer             -- 1 byte
---@field CompressionType integer  -- 1 byte
---@field Paddings string          -- 2 bytes
---@field Name string              -- 16 bytes
ffi.cdef [[
  typedef struct {
    int32_t Position;         // 4 bytes
    int32_t Size;             // 4 bytes
    int32_t CompressedSize;   // 4 bytes
    uint8_t Type;             // 1 byte
    uint8_t CompressionType;  // 1 byte
    char Paddings[2];         // 2 bytes
    char Name[16];            // 16 bytes
  } WadItemHeader;
]]

-- ===============================================
-- TexHeader
-- ===============================================

---@class TexHeader
---@field Name string      -- 16 bytes
---@field Width integer    -- 4 bytes
---@field Height integer   -- 4 bytes
---@field Data any         -- variable size (handled dynamically in LuaJIT)
ffi.cdef [[
  typedef struct {
    char Name[16];        // 16 bytes
    int32_t Width;        // 4 bytes
    int32_t Height;       // 4 bytes
    uint8_t Data[];       // variable size (handled dynamically in LuaJIT)
  } TexHeader;
]]

-- ===============================================
-- PakHeader
-- ===============================================

---@class PakHeader
---@field Code string     -- 4 bytes
---@field Offset integer  -- 4 bytes
---@field Length integer  -- 4 bytes
ffi.cdef [[
  typedef struct {
    char Code[4];         // 4 bytes
    int32_t Offset;       // 4 bytes
    int32_t Length;       // 4 bytes
  } PakHeader;
]]

---@type string
PAK_MAGIC = "PACK"

-- ===============================================
-- PakItemHeader
-- ===============================================

---@class PakItemHeader
---@field Name string       -- 56 bytes
---@field Position integer  -- 4 bytes
---@field Length integer    -- 4 bytes
ffi.cdef [[
  typedef struct {
    char Name[56];        // 56 bytes
    int32_t Position;     // 4 bytes
    int32_t Length;       // 4 bytes
  } PakItemHeader;
]]

-- ===============================================
-- LumpHeader
-- ===============================================

---@class LumpHeader
---@field Width integer   -- 4 bytes
---@field Height integer  -- 4 bytes
---@field Data any        -- variable size (handled dynamically in LuaJIT)
ffi.cdef [[
  typedef struct {
    int32_t Width;        // 4 bytes
    int32_t Height;       // 4 bytes
    uint8_t Data[];       // variable size (handled dynamically in LuaJIT)
  } LumpHeader;
]]

-- ===============================================
-- RGBColor
-- ===============================================

---@class RGBColor
---@field Red integer      -- 1 byte (0-255)
---@field Green integer    -- 1 byte (0-255)
---@field Blue integer     -- 1 byte (0-255)
ffi.cdef [[
  typedef struct {
    uint8_t Red;          // 1 byte
    uint8_t Green;        // 1 byte
    uint8_t Blue;         // 1 byte
  } RGBColor;
]]

-- ===============================================
-- PaletteData
-- ===============================================

---@class PaletteData
---@field Colors RGBColor[]  -- Typically 256 colors in a palette
ffi.cdef [[
  typedef struct {
    RGBColor Colors[256]; // Typically 256 colors in a palette
  } PaletteData;
]]
