CC = gcc
DEBUG_FLAGS = -g -o0
RELEASE_FLAGS = -O3
CFLAGS = $(DEBUG_FLAGS)
DEFS = -DSPNG_USE_MINIZ
LIBS = -llua5.4
INC = -I. 
BIN = sqt

SRC = \
	libs/c/minizip/miniz.c \
	libs/c/lfs/lfs.c \
	libs/c/spng/spng.c \
	libs/c/spng/module.c \
	src/main.c

clean:
	rm -rf UNPAK
	rm $(BIN)

build: 
	$(CC) $(DEFS) $(CFLAGS) $(SRC) -o $(BIN) $(LIBS) $(INC) -lm

### ===============================================
### DEBUG TARGETS
### ===============================================

pak_info:
	@./$(BIN) \
		pak \
		info \
		-i /home/sepi/Projects/internet/games/quake/game/id1/pak0.pak

pak_list:
	@./$(BIN) \
		pak \
		list \
		-i /home/sepi/Projects/internet/games/quake/game/id1/pak0.pak

pak_extract:
	@./$(BIN) \
		pak \
		extract \
		-i /home/sepi/Projects/internet/games/quake/game/id1/pak0.pak \
		-o ignore/quake/PAK

pak_create:
	@./$(BIN) \
		pak \
		create \
		-i ignore/quake/PAK/ \
		-o ignore/mypak.PAK

pak_info_me:
	@./$(BIN) \
		pak \
		info \
		-i ignore/mypak.PAK


pak_list_me:
	@./$(BIN) \
		pak \
		list \
		-i ignore/mypak.PAK

unlmp:
	@./$(BIN) \
		unlmp \
		ignore/quake/PAK/gfx/bigbox.lmp \
		ignore/quake/PAK/gfx/palette.lmp \
		ignore/quake/sepi/lmp/bigbox.png

unwad:
	@./$(BIN) \
		unwad \
		ignore/quake/PAK/gfx/base.wad \
		ignore/quake/WAD/base

xunwad:
	@./$(BIN) \
		unwad \
		ignore/quake/PAK/gfx/all.wad \
		ignore/quake/WAD/all