local _pak = require('src.pak')
local _lmp = require('src.lmp')
local _wad = require('src.wad')
local argparse = require("libs.lua.argparse.argparse")

local parser = argparse()
    :name "sqt"
    :description "A set of tools to work with quake (I) files"
    :epilog "For more info, see http://sepi.me/qtools"

parser:flag("-v --verbose", "show debug logs"):action(function ()
  _G.VERBOSE = true
end)
-- ==================================================================
--  pak top command
-- ==================================================================
local pak = parser:command(
  "pak",
  "this command deals with the .PAK files"
)

-- ---------------------------------
-- pak -> info sub command
local pak_info = pak:command("info", "use this to get some details about a .PAK file")
pak_info:option("-i --input", "set the .PAK file input path"):target("input"):args(1)
pak_info:action(function (args)
  if not args.input then
    print(pak_info:get_help())
    os.exit(1)
  end
  _pak.info(args.input)
end)

-- ---------------------------------
-- pak -> list sub command
local pak_list = pak:command("list", "use this to list items in a .PAK file")
pak_list:option("-i --input", "set the .PAK file input path"):target("input"):args(1)
pak_list:action(function (args)
  if not args.input then
    print(pak_list:get_help())
    os.exit(1)
  end
  _pak.list(args.input)
end)

-- ---------------------------------
-- pak -> extract sub command
local pak_extract = pak:command("extract", "use this to extract items in a .PAK file")
pak_extract:option("-i --input", "set the .PAK file input path"):target("input"):args(1)
pak_extract:option("-o --output", "set the extraction path (directory)"):target("output"):args(1)
pak_extract:action(function (args)
  if not args.input or not args.output then
    print(pak_extract:get_help())
    os.exit(1)
  end
  _pak.extract(args.input, args.output)
end)

-- ---------------------------------
-- pak -> create sub command
local pak_create = pak:command("create", "use this to create a .PAK file")
pak_create:option("-i --input", "set the input directory path"):target("input"):args(1)
pak_create:option("-o --output", "set the output .PAK file path"):target("output"):args(1)
pak_create:action(function (args)
  if not args.input or not args.output then
    print(pak_create:get_help())
    os.exit(1)
  end
  _pak.create(args.input, args.output)
end)

-- ==================================================================
--  lmp top command
-- ==================================================================
local lmp = parser:command(
  "lmp",
  "this command deals with the .LMP files"
)

-- ---------------------------------
-- lmp -> info sub command
local lmp_info = lmp:command("info", "use this to get some details about a .LMP file")
lmp_info:option("-i --input", "set the .LMP file input path"):target("input"):args(1)
lmp_info:action(function (args)
  if not args.input then
    print(lmp_info:get_help())
    os.exit(1)
  end
  _lmp.info(args.input)
end)

-- ---------------------------------
-- lmp -> decode sub command
local lmp_decode = lmp:command("decode", "use this to decode a .LMP file into a .png image")
lmp_decode:option("-i --input", "set the .LMP file input path"):target("input"):args(1)
lmp_decode:option("-p --palette", "set the input palette file path"):target("palette"):args(1)
lmp_decode:option("-o --output", "set the output .png file path"):target("output"):args(1)
lmp_decode:action(function (args)
  if not args.input or not args.palette or not args.output then
    print(lmp_decode:get_help())
    os.exit(1)
  end
  _lmp.decode(args.input, args.palette, args.output)
end)

-- ---------------------------------
-- lmp -> encode sub command
local lmp_encode = lmp:command("encode", "use this to encode a .png image into a .LMP file")
lmp_encode:option("-i --input", "set the input .png file path"):target("input"):args(1)
lmp_encode:option("-p --palette", "set the input palette file path"):target("palette"):args(1)
lmp_encode:option("-o --output", "set the output .LMP file path"):target("output"):args(1)
lmp_encode:action(function (args)
  if not args.input or not args.palette or not args.output then
    print(lmp_encode:get_help())
    os.exit(1)
  end
  _lmp.encode(args.input, args.output, args.palette)
end)

-- ==================================================================
--  wad top command
-- ==================================================================
local wad = parser:command(
  "wad",
  "this command deals with the .WAD files"
)

-- ---------------------------------
-- wad -> info sub command
local wad_info = wad:command("info", "use this to get some details about a .WAD file")
wad_info:option("-i --input", "set the .WAD file input path"):target("input"):args(1)
wad_info:action(function (args)
  if not args.input then
    print(wad_info:get_help())
    os.exit(1)
  end
  -- TODO: implement this
  print("NOT IMPLEMENTED YET!")
end)

-- ---------------------------------
-- wad -> list sub command
local wad_list = wad:command("list", "use this to list items in a .WAD file")
wad_list:option("-i --input", "set the .WAD file input path"):target("input"):args(1)
wad_list:action(function (args)
  if not args.input then
    print(wad_list:get_help())
    os.exit(1)
  end
  -- TODO: implement this
  print("NOT IMPLEMENTED YET!")
end)

-- ---------------------------------
-- wad -> extract sub command
local wad_extract = wad:command("extract", "use this to extract items in a .WAD file")
wad_extract:option("-i --input", "set the .WAD file input path"):target("input"):args(1)
wad_extract:option("-o --output", "set the extraction path (directory)"):target("output"):args(1)
wad_extract:action(function (args)
  if not args.input or not args.output then
    print(wad_extract:get_help())
    os.exit(1)
  end
  pak.cmd(args.input, args.output)
end)

-- ---------------------------------
-- wad -> create sub command
local wad_create = wad:command("create", "use this to create a .WAD file")
wad_create:option("-i --input", "set the input directory path"):target("input"):args(1)
wad_create:option("-o --output", "set the output .WAD file path"):target("output"):args(1)
wad_create:action(function (args)
  if not args.input or not args.output then
    print(wad_create:get_help())
    os.exit(1)
  end
  print("NOT IMPLEMENTED YET!")
end)


parser:parse()
