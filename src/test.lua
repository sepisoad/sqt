local foo = require('foo')
local lfs = require('lfs')

print(
  foo.to_uppercase(
    lfs.currentdir()))
