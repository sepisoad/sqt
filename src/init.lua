local unpak = require('src.cmd.unpak')
local unlmp = require('src.cmd.unlmp')
local unwad = require('src.cmd.unwad')
local argparse = require("libs.lua.argparse.argparse")

-- DEFINE ARGS
local parser = argparse()
    :name "qtools"
    :description "A set of tools to work with quake (I) files"
    :epilog "For more info, see http://sepi.me/qtools"

-- DEFINE THE UNPAK COMMAND
local cmd_unpak = parser:command(
  "unpak",
  "this command will extract all files from a .PAK file into a directory"
)
cmd_unpak:argument("input", "define where to load the .PAK file from")
cmd_unpak:argument("output", "define where to extract the .PAK file to")
cmd_unpak:action(function(args)
  unpak.cmd(
    args.input,
    args.output)
end)

-- DEFINE THE UNLMP COMMAND
local cmd_unlmp = parser:command(
  "unlmp",
  "this command will convert a 2d image data stored in a .LMP file into a .png file"
)
cmd_unlmp:argument("input", "define where to load the .LMP image file from")
cmd_unlmp:argument("palette", "define where to load the .LMP palette file from")
cmd_unlmp:argument("output", "define file name which to save image data into")
cmd_unlmp:action(function(args)
  unlmp.cmd(
    args.input,
    args.palette,
    args.output)
end)

-- DEFINE THE UNWAD COMMAND
local cmd_unlmp = parser:command(
  "unwad",
  "this command will TODO:sepi:"
)
cmd_unlmp:argument("input", "define where to load the .WAD file from")
cmd_unlmp:argument("output", "define where to extract the lump files to")
cmd_unlmp:action(function(args)
  unwad.cmd(
    args.input,
    args.output)
end)

parser:parse()
