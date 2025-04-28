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
  targetdir "BUILD"
  objdir "BUILD"
  targetname "log"
  files {"deps/log.c"}

-- Skeeto optparse Library
project "mk_args"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD"
  objdir "BUILD"
  targetname "args"
  files {"deps/optparse.c"}
  
-- FS Library
project "mk_fs"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD"
  objdir "BUILD"
  targetname "fs"
  buildoptions { "-Wno-deprecated-declarations" }
  files {"deps/fs.c"}

-- STB Library
project "mk_stb"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD"
  objdir "BUILD"
  targetname "stb"
  buildoptions { "-Wno-deprecated-declarations" }
  files {"deps/stb.c"}

-- Sokol Library
project "mk_sokol"
  kind "StaticLib"
  language "C"
  location "BUILD"
  targetdir "BUILD"
  objdir "BUILD"
  targetname "sokol"
  files {"deps/sokol.c"}

  filter "system:macosx"
    -- defines { "SOKOL_GLCORE" }
    links { "Cocoa.framework", "OpenGL.framework", "IOKit.framework" }
    buildoptions { "-x objective-c" }

  filter "system:linux"
    -- defines { "SOKOL_GLCORE" }
    links { "X11", "Xi", "Xcursor", "GL", "m" }

-- Main Application
project "mk_sqt"
  kind "ConsoleApp"
  language "C"
  location "BUILD"
  targetdir "BUILD"
  objdir "BUILD"
  targetname "sqt"
  files {
    "src/*.c",
    "src/cmd/*.c",
    "src/pak/*.c",
    "src/lmp/*.c",
    "src/wad/*.c",
    "src/ui/*.c",
  }
  includedirs {"src", "deps"}
  links { "mk_log:static", "mk_args:static", "mk_fs:static", "mk_stb:static", "mk_sokol:static" }
  buildoptions { "-std=c2x" }
  defines { "SOKOL_GLCORE" }
  defines { "_POSIX_C_SOURCE=199309L" }  -- Needed for some C23 features

  filter "system:macosx"
    links { "Cocoa.framework", "OpenGL.framework", "IOKit.framework" }

  filter "system:linux"
    links { "X11", "Xi", "Xcursor", "GL", "m" }

-- GLSL Shader Compilation Action
newaction {
  trigger = "glsl",
  description = "Compile shaders into C headers",
  execute = function()
    os.execute("sokol-shdc -i res/shaders/default.glsl -l glsl410 -f sokol -o src/glsl/default.h")
  end
}

-- Run Action 1
newaction {
  trigger = "1",
  description = "1",
  execute = function()
    os.execute("BUILD/sqt pak info -i /Users/sepi/Downloads/mod/lq1/pak0.pak")
  end
}

-- Run Action 2
newaction {
  trigger = "2",
  description = "2",
  execute = function()
    os.execute("BUILD/sqt pak list -i /Users/sepi/Downloads/mod/lq1/pak0.pak")
  end
}

-- Run Action 3
newaction {
  trigger = "3",
  description = "3",
  execute = function()
    os.execute("BUILD/sqt pak extract -i /Users/sepi/Downloads/mod/lq1/pak0.pak -o /Users/sepi/Downloads/mod-x")
  end
}

-- Run Action 4
newaction {
  trigger = "4",
  description = "4",
  execute = function()
    os.execute("BUILD/sqt pak extract -i /Users/sepi/Games/Quake1/bonkjam/pak0.pak -o /Users/sepi/Downloads/mod-xxx")
  end
}


