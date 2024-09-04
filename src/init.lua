-- ADD LOCAL LIB DIR TO LUA PACKAGE SEARCH PATH
package.cpath = package.cpath .. ";libs/shared/?.so"

-- LOAD PACKAGES
local unpaker = require('src.unpaker')

-- RUN THE COMMAND
unpaker.unpak()