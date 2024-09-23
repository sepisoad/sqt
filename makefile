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

### ===============================================
lmp_info:
	@./$(BIN) \
		lmp \
		info \
		-i ignore/quake/PAK/gfx/bigbox.lmp

lmp_decode:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/quake/PAK/gfx/bigbox.lmp \
		-p ignore/quake/PAK/gfx/palette.lmp \
		-o ignore/LMP/X/Y/Z/gfx/bigbox.png

lmp_encode:
	@./$(BIN) \
		lmp \
		encode \
		-i ignore/LMP/X/Y/Z/gfx/bigbox.png \
		-p ignore/quake/PAK/gfx/palette.lmp \
		-o ignore/LMP/X/Y/Z/gfx/bigbox.lmp

lmp_decode_me:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/LMP/X/Y/Z/gfx/bigbox.lmp \
		-p ignore/quake/PAK/gfx/palette.lmp \
		-o ignore/LMP/X/Y/Z/gfx/bigbox_me.png

lmp_encode_non:
	@./$(BIN) \
		lmp \
		encode \
		-i ignore/LMP/X/Y/Z/gfx/sqt.png \
		-p ignore/quake/PAK/gfx/palette.lmp \
		-o ignore/LMP/X/Y/Z/gfx/sqt.lmp

lmp_decode_non:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/LMP/X/Y/Z/gfx/sqt.lmp \
		-p ignore/quake/PAK/gfx/palette.lmp \
		-o ignore/LMP/X/Y/Z/gfx/sqt_non.png

### ===============================================
wad_info:
	@./$(BIN) \
		wad \
		info \
		-i ignore/quake/PAK/gfx/all.wad

wad_list:
	@./$(BIN) \
		wad \
		list \
		-i ignore/quake/PAK/gfx/all.wad

wad_extract:
	@./$(BIN) \
		wad \
		extract \
		-i ignore/quake/PAK/gfx/all.wad \
		-o ignore/WAD/gfx

wad_create:
	@./$(BIN) \
		wad \
		create \
		-i ignore/WAD/gfx \
		-o ignore/WAD/gfx.wad

### ===============================================
tex_info:
	@./$(BIN) \
		tex \
		info \
		-i ignore/quake/PAK/gfx/bigbox.lmp

tex_decode:
	@./$(BIN) \
		tex \
		encode \
		BRRRRRR

tex_encode:
	@./$(BIN) \
		tex \
		encode \
		BRRRRRR