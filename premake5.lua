---@diagnostic disable: undefined-global

workspace "ProjectWorkspace"
  configurations { "Debug", "Release" }
  location "."

  filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"
    optimize "Off"
    buildoptions { "-fsanitize=address" }
    linkoptions { "-fsanitize=address" }

  filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "Speed"

-- Rxi Log Library
project "mk_log"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD/"
  objdir "BUILD/obj"
  targetname "log"
  files {"deps/log.c"}

-- Skeeto optparse Library
project "mk_args"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD/"
  objdir "BUILD/obj"
  targetname "args"
  files {"deps/optparse.c"}
  
-- FS Library
project "mk_fs"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD/"
  objdir "BUILD/obj"
  targetname "fs"
  buildoptions { "-Wno-deprecated-declarations" }
  files {"deps/fs.c"}

-- STB Library
project "mk_stb"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD/"
  objdir "BUILD/obj"
  targetname "stb"
  buildoptions { "-Wno-deprecated-declarations" }
  files {"deps/stb.c"}

-- Main Application
project "mk_sqt"
  kind "ConsoleApp"
  language "C"
  location "BUILD"
  targetdir "BUILD/"
  objdir "BUILD/obj"
  targetname "sqt"
  files {"src/*.c", "src/qk/*.c"}
  includedirs {"src", "deps"}
  links { "mk_log:static", "mk_args:static", "mk_fs:static", "mk_stb:static" }
  buildoptions { "-std=c2x" }
  defines { "_POSIX_C_SOURCE=199309L" }  -- Needed for some C23 features
  
-- Run Action 1
newaction {
  trigger = "r",
  description = "quick execute",
  execute = function()
    os.execute("BUILD/sqt -m=KEEP/armor.mdl")
  end
}

-- Run Action 2
newaction {
  trigger = "rr",
  description = "execute with args",
  execute = function()
    -- Capture additional command-line arguments
    local args = _ARGS
    local args_str = table.concat(args, " ")
    
    -- Execute the program with arguments
    os.execute("BUILD/sqt " .. args_str)
  end
}

