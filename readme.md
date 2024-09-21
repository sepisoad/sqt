# Sepi's Quake Tools (SQT)

SQT is a set of commands to work with quake 1 files.

The code is licensed under GNU general public license version 3 (GPLv3)

# How to build
The build commands need some refinement, but the code itself is easy to compile and fully portable. My priority is to get the code into the desired state first, after which I’ll update the Makefile to streamline the build process.

# How to use

SQT comes with a lot of sub commands to work with various quake files.

items marked as ✅ are already implemented.

items marked as ❌ are NOT implemented YET.


## to level commands
- pak: this command deals with the .PAK files
- lmp: this command deals with the .LMP files
- wad: this command deals with the .WAD files

## pak command
- ✅ info: this command deals with the .PAK files
- ✅ list: use this to list items in a .PAK file
- ✅ extract: use this to extract items in a .PAK file
- ✅ create: use this to create a .PAK file

## lmp command
- ❌ info: use this to get some details about a .LMP file
- ❌ decode: use this to decode a .LMP file into a .png image
- ❌ encode: use this to encode a .png image into a .LMP file

## wad command
- ❌ info: use this to get some details about a .WAD file
- ❌ list: use this to list items in a .WAD file
- ❌ extract: use this to extract items in a .WAD file
- ❌ create: use this to create a .WAD file


## other file types to cover soon
- NAV
- BSP
- LIT
- MDL
- MD5ANIM
- MD5MESH
- BNVIB
- DEM
- BIN
- DAT

# Credtis:
- [lua](https://www.lua.org/)
- [lua files ystem](http://lunarmodules.github.io/luafilesystem)
- [miniz](https://github.com/richgel999/miniz)
- [spng](https://github.com/randy408/libspng/tree/master/spng)

# Notes:
- [ ] consider using this: https://github.com/KaisenAmin/c_std