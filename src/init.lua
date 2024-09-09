local unpak = require('src.cmd.unpak')
local unlmp = require('src.cmd.unlmp')
local pprint = require("libs.lua.pprint.pprint")
local argparse = require("libs.lua.argparse.argparse")

-- DEFINE ARGS
local parser = argparse()
    :name "qtools"
    :description "A set of tools to work with quake (I) files"
    :epilog "For more info, see http://sepi.me/qtools"

-- DEFINE THE UNPAK COMMAND
local cmd_unpak = parser:command("unpak")
cmd_unpak:argument("input", "define where to load the .PAK file from")
cmd_unpak:argument("output", "define where to extract the .PAK file to")
cmd_unpak:action(function(args)
  unpak.cmd(args.input, args.output)
end)

local cmd_unlmp = parser:command("unlmp")
cmd_unlmp:argument("input", "define where to load the .LMP image file from")
cmd_unlmp:argument("palette", "define where to load the .LMP palette file from")
cmd_unlmp:argument("output", "define where to save image data to")
cmd_unlmp:action(function(args)
  unlmp.cmd(args.input, args.palette, args.output)
end)

parser:parse()