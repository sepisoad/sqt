local fs = require('lfs')
local log = require('libs.lua.log.log')
local path = require('libs.lua.dir.path')
local dir = require('libs.lua.dir.dir')
local pprint = require('libs.lua.pprint.pprint')


local create_dir_if_doesnt_exist = function(p)
  if not path.exists(p) then
    if not dir.makepath(p) then
      log.err(string.format("failed to create extraction directory at '%s'", p))
      os.exit(1)
    end
  end
end

local join_item_path = function (dir, item)
  local full = path.join(dir, item)
  local base = path.dirname(full)
  return full, base
end

local get_file_disk_size = function (p)
  if not path.exists(p) then
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