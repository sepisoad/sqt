local QOI_MAGIC = string.byte("q") << 24 | string.byte("o") << 16 | string.byte("i") << 8 | string.byte("f")
local QOI_HEADER_SIZE = 14
local QOI_PIXELS_MAX = 400000000

local QOI_SRGB = 0
local QOI_LINEAR = 1

local QOI_OP_INDEX = 0x00
local QOI_OP_DIFF = 0x40
local QOI_OP_LUMA = 0x80
local QOI_OP_RUN = 0xc0
local QOI_OP_RGB = 0xfe
local QOI_OP_RGBA = 0xff
local QOI_MASK_2 = 0xc0

local qoi_padding = { 0, 0, 0, 0, 0, 0, 0, 1 }

local function qoi_color_hash(C)
  return ((C.r * 3) + (C.g * 5) + (C.b * 7) + (C.a * 11)) % 64
end

local function qoi_write_32(bytes, v)
  table.insert(bytes, (v & 0xff000000) >> 24)
  table.insert(bytes, (v & 0x00ff0000) >> 16)
  table.insert(bytes, (v & 0x0000ff00) >> 8)
  table.insert(bytes, (v & 0x000000ff))
end

local function qoi_encode(data, desc)
  if not data or not desc or desc.width == 0 or desc.height == 0 or desc.channels < 3 or desc.channels > 4 or desc.colorspace > 1 then
    return nil
  end

  -- local max_size = desc.width * desc.height * (desc.channels + 1) + QOI_HEADER_SIZE + #qoi_padding
  local bytes = {}

  qoi_write_32(bytes, QOI_MAGIC)
  qoi_write_32(bytes, desc.width)
  qoi_write_32(bytes, desc.height)
  table.insert(bytes, desc.channels)
  table.insert(bytes, desc.colorspace)

  -- The encoding process starts here
  local index = {}
  for i = 0, 63 do index[i] = { r = 0, g = 0, b = 0, a = 255 } end

  local px_prev = { r = 0, g = 0, b = 0, a = 255 }
  local run = 0

  for i = 1, #data, desc.channels do
    local px = {
      r = data[i],
      g = data[i + 1],
      b = data[i + 2],
      a = desc.channels == 4 and data[i + 3] or 255
    }

    if px.r == px_prev.r and px.g == px_prev.g and px.b == px_prev.b and px.a == px_prev.a then
      run = run + 1
      if run == 62 or i == #data then
        table.insert(bytes, QOI_OP_RUN | (run - 1))
        run = 0
      end
    else
      if run > 0 then
        table.insert(bytes, QOI_OP_RUN | (run - 1))
        run = 0
      end

      local index_pos = qoi_color_hash(px)
      if index[index_pos].r == px.r and index[index_pos].g == px.g and index[index_pos].b == px.b and index[index_pos].a == px.a then
        table.insert(bytes, QOI_OP_INDEX | index_pos)
      else
        index[index_pos] = px

        if px.a == px_prev.a then
          local vr = px.r - px_prev.r
          local vg = px.g - px_prev.g
          local vb = px.b - px_prev.b

          if vr > -3 and vr < 2 and vg > -3 and vg < 2 and vb > -3 and vb < 2 then
            table.insert(bytes, QOI_OP_DIFF | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2))
          else
            table.insert(bytes, QOI_OP_RGB)
            table.insert(bytes, px.r)
            table.insert(bytes, px.g)
            table.insert(bytes, px.b)
          end
        else
          table.insert(bytes, QOI_OP_RGBA)
          table.insert(bytes, px.r)
          table.insert(bytes, px.g)
          table.insert(bytes, px.b)
          table.insert(bytes, px.a)
        end
      end
    end

    px_prev = px
  end

  for i = 1, #qoi_padding do
    table.insert(bytes, qoi_padding[i])
  end

  return bytes
end

---@param buffer any
---@param palette any
---@param width integer
---@param height integer
---@return any
local function qoi_encode_indexed(buffer, palette, width, height)
  local rgba_data = {}

  for i = 1, #buffer do
    local index = string.byte(buffer, i)
    local color = palette[index + 1]

    table.insert(rgba_data, color.Red)   -- R
    table.insert(rgba_data, color.Green) -- G
    table.insert(rgba_data, color.Blue)  -- B
  end

  local desc = {
    width = width,
    height = height,
    channels = 3,
    colorspace = QOI_SRGB, --QOI_LINEAR, -- or QOI_SRGB
  }

  local encoded_data = qoi_encode(rgba_data, desc)
  if encoded_data == nil then return "" end

  local data = {}
  for idx = 1, #encoded_data do
    table.insert(data, string.char(encoded_data[idx]))
  end
  return table.concat(data)
end

local function find_closest_palette_index(r, g, b, palette)
  local closest_distance = math.huge
  for i, color in ipairs(palette) do
    local pr, pg, pb = color.Red, color.Green, color.Blue
    local distance = (r - pr) ^ 2 + (g - pg) ^ 2 + (b - pb) ^ 2
    if distance < closest_distance then
      closest_distance = distance
    end
  end

  return 0
end

local function find_palette_index(r, g, b, palette)
  for i, color in ipairs(palette) do
    if r == color.Red and g == color.Green and b == color.Blue then
      return i - 1
    end
  end

  return find_closest_palette_index(r,g,b, palette)
end

local function qoi_read_32(bytes, p)
  local a = string.byte(bytes, p + 0)
  local b = string.byte(bytes, p + 1)
  local c = string.byte(bytes, p + 2)
  local d = string.byte(bytes, p + 3)
  return (a << 24) | (b << 16) | (c << 8) | d, p + 4
end

local function qoi_read_8(bytes, p)
  local a = string.byte(bytes, p)
  return a, p + 1
end

local function wrap8(val)
  return (val % 256)
end


local function qoi_decode(bytes, size, desc, channels)
  if not bytes or
      not desc or
      (channels ~= 0 and channels ~= 3 and channels ~= 4) or
      size < QOI_HEADER_SIZE + #qoi_padding then
    return nil
  end

  local p = 1
  local header_magic
  header_magic, p = qoi_read_32(bytes, p)
  desc.width, p = qoi_read_32(bytes, p)
  desc.height, p = qoi_read_32(bytes, p)
  desc.channels, p = qoi_read_8(bytes, p)
  desc.colorspace, p = qoi_read_8(bytes, p)

  if desc.width <= 0 or
      desc.height <= 0 or
      desc.channels < 3 or
      desc.channels > 4 or
      desc.colorspace > 1 or
      header_magic ~= QOI_MAGIC then
    return nil
  end

  if channels == 0 then channels = desc.channels end

  local px_len = desc.width * desc.height * channels
  local pixels = {}
  local index = {}
  for i = 0, 63 do index[i] = { r = 0, g = 0, b = 0, a = 255 } end

  local px = { r = 0, g = 0, b = 0, a = 255 }
  local run = 0

  local chunks_len = size - #qoi_padding

  for px_pos = 1, px_len, channels do
    if run > 0 then
      run = run - 1
    elseif p <= chunks_len then
      local b1
      b1, p = qoi_read_8(bytes, p)

      if b1 == QOI_OP_RGB then
        px.r, p = qoi_read_8(bytes, p)
        px.g, p = qoi_read_8(bytes, p)
        px.b, p = qoi_read_8(bytes, p)
      elseif b1 == QOI_OP_RGBA then
        px.r, p = qoi_read_8(bytes, p)
        px.g, p = qoi_read_8(bytes, p)
        px.b, p = qoi_read_8(bytes, p)
        px.a, p = qoi_read_8(bytes, p)
      elseif (b1 & QOI_MASK_2) == QOI_OP_INDEX then
        px = { r = index[b1].r, g = index[b1].g, b = index[b1].b, a = index[b1].a }
      elseif (b1 & QOI_MASK_2) == QOI_OP_DIFF then
        px.r = wrap8(px.r + ((b1 >> 4) & 0x03) - 2)
        px.g = wrap8(px.g + ((b1 >> 2) & 0x03) - 2)
        px.b = wrap8(px.b + (b1 & 0x03) - 2)
      elseif (b1 & QOI_MASK_2) == QOI_OP_LUMA then
        local b2
        b2, p = qoi_read_8(bytes, p)
        local vg = (b1 & 0x3f) - 32
        local vg_r = ((b2 >> 4) & 0x0f) - 8
        local vg_b = (b2 & 0x0f) - 8
        px.r = wrap8(px.r + vg + vg_r)
        px.g = wrap8(px.g + vg)
        px.b = wrap8(px.b + vg + vg_b)
      elseif (b1 & QOI_MASK_2) == QOI_OP_RUN then
        run = (b1 & 0x3f)
      end

      local index_pos = qoi_color_hash(px)
      index[index_pos] = { r = px.r, g = px.g, b = px.b, a = px.a }
    end

    table.insert(pixels, px.r)
    table.insert(pixels, px.g)
    table.insert(pixels, px.b)
    if channels == 4 then
      table.insert(pixels, px.a)
    end
  end

  return pixels
end

---@param qoi_data any
---@param palette any
---@return any, integer, integer
local function qoi_decode_indexed(qoi_data, palette)
  local desc = {}
  local channels = 3 -- RGB!
  local decoded_pixels = qoi_decode(qoi_data, #qoi_data, desc, channels)

  if not decoded_pixels then
    return nil, 0, 0
  end

  local indexed_buffer = {}

  for i = 1, #decoded_pixels, 3 do
    local r = decoded_pixels[i]
    local g = decoded_pixels[i + 1]
    local b = decoded_pixels[i + 2]

    -- local palette_index = find_closest_palette_index(r, g, b, palette)
    local palette_index = find_palette_index(r, g, b, palette)
    table.insert(indexed_buffer, palette_index)
  end

  local data = {}
  for idx = 1, #indexed_buffer do
    table.insert(data, string.char(indexed_buffer[idx]))
  end

  return table.concat(data), desc.width, desc.height
  -- return indexed_buffer, desc.width, desc.height
end



return {
  encode = qoi_encode,
  decode = qoi_decode,
  encode_indexed = qoi_encode_indexed,
  decode_indexed = qoi_decode_indexed
}
