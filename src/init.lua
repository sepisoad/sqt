local unpaker = require('src.cmd.unpaker')
local pprint = require("libs.lua.pprint.pprint")
local argparse = require("libs.lua.argparse.argparse")

-- DEFINE ARGS
local parser = argparse()
   :name "qtools"
   :description "A set of tools to work with quake (I) files"
   :epilog "For more info, see http://sepi.me/qtools"

-- DEFINE THE UNPAK COMMAND
local cmd_unpak = parser:command("unpak")
local cmd_unpak_args =cmd_unpak:argument("input", "define where to load the PAK file from")
local cmd_unpak_args =cmd_unpak:argument("output", "define where to extract the PAK file to")

cmd_unpak:action(function(args)
  unpaker.unpak(args.input, args.output)
end)

local cliargs = parser:parse()

-- pprint(cliargs)

-- 