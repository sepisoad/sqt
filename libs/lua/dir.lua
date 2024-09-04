--- Listing files in directories and creating/removing directory paths.
--
-- Dependencies: `pl.utils`, `pl.path`
--
-- Soft Dependencies: `alien`, `ffi` (either are used on Windows for copying/moving files)
-- @module pl.dir

local utils = require 'libs.lua.utils'
local path = require 'libs.lua.path'
local mkdir = path.mkdir

local assert_string = utils.assert_string
local dir = {}

do
  local dirpat
  if path.is_windows then
      dirpat = '(.+)\\[^\\]+$'
  else
      dirpat = '(.+)/[^/]+$'
  end

  local _makepath
  function _makepath(p)
      -- windows root drive case
      if p:find '^%a:[\\]*$' then
          return true
      end
      if not path.isdir(p) then
          local subp = p:match(dirpat)
          if subp then
            local ok, err = _makepath(subp)
            if not ok then return nil, err end
          end
          return mkdir(p)
      else
          return true
      end
  end

  --- create a directory path.
  -- This will create subdirectories as necessary!
  -- @string p A directory path
  -- @return true on success, nil + errormsg on failure
  -- @raise failure to create
  function dir.makepath (p)
      assert_string(1,p)
      if path.is_windows then
          p = p:gsub("/", "\\")
      end
      return _makepath(path.abspath(p))
  end
end


return dir