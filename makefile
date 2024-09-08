# TODO: improve Makefile
# build:
# 	gcc -g -o0 -o qtools src/main.c libs/c/lfs/lfs.c -llua5.4 -I.

build:
	gcc -g -o0 -o qtools libs/c/foo/foo.c src/main.c  -llua5.4 -I.
	

unpak:
	@lua src/init.lua "/home/sepi/Projects/internet/games/quake/game/id1/pak0.pak" "/home/sepi/Projects/sepi/quake-tools/unpaker/UNPAK"