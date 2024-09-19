local fs = require('lfs')
local mfs = require('libs.lua.minifs.minifs')
local log = require('libs.lua.log.log')


local create_dir_if_doesnt_exist = function(p)
  if not mfs.exists(p) then
    if not mfs.mkrdir(p) then
      log.err(string.format("failed to create extraction directory at '%s'", p))
      os.exit(1)
    end
  end
end

local join_item_path = function (dir, item)
  local full = mfs.join(dir, item)
  local base = mfs.dirname(full)
  return full, base
end

local get_file_disk_size = function (p)
  if not mfs.exists(p) then
    log.err(string.format("failed to open '%s'", p))
    os.exit(1)
  end

  local attr = fs.attributes(p)
  if not attr.size then
    log.warn(string.format("cannot get file disk size for '%s'", p))
    return 0
  end
  return attr.size
end

return {
  create_dir_if_doesnt_exist = create_dir_if_doesnt_exist,
  join_item_path = join_item_path,
  get_file_disk_size = get_file_disk_size,
}