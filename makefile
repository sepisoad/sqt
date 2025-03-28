CC = gcc
DEBUG_FLAGS = -g -o0
RELEASE_FLAGS = -O3
CFLAGS = $(DEBUG_FLAGS)
DEFS = -DSPNG_USE_MINIZ
LIBS = -L/Users/sepi/Downloads/lua-5.4.7 -llua
INC = -I. -I/Users/sepi/Downloads/lua-5.4.7
BIN = sqt

SRC = \
	libs/c/lfs/lfs.c \
	libs/c/stb/img.c \
	src/main.c

clean:
	rm -rf ignore
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
		-i /Users/sepi/Games/Quake1/id1/pak0.pak

pak_list:
	@./$(BIN) \
		pak \
		list \
		-i /Users/sepi/Games/Quake1/id1/pak0.pak

pak_extract:
	@./$(BIN) \
		pak \
		extract \
		-i /Users/sepi/Games/Quake1/id1/pak0.pak \
		-o ignore/UNPAK

pak_create:
	@./$(BIN) \
		pak \
		create \
		-i ignore/UNPAK/ \
		-o ignore/mypak.pak

pak_extract_me:
	@./$(BIN) \
		pak \
		extract \
		-i ignore/mypak.pak \
		-o ignore/UNPAK_ME/

### ===============================================
lmp_info:
	@./$(BIN) \
		lmp \
		info \
		-i ignore/UNPAK/gfx/weapons/ww_axe_1.lmp

lmp_decode:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/UNPAK/gfx/weapons/ww_axe_1.lmp \
		-p ignore/UNPAK/gfx/palette.lmp \
		-o ignore/UNLMP/ww_axe_1.png

lmp_encode:
	@./$(BIN) \
		lmp \
		encode \
		-i ignore/UNLMP/ww_axe_1.png \
		-p ignore/UNPAK/gfx/palette.lmp \
		-o ignore/UNLMP/ww_axe_1.lmp

lmp_decode_me:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/UNLMP/ww_axe_1.lmp \
		-p ignore/UNPAK/gfx/palette.lmp \
		-o ignore/UNLMP/ww_axe_1_me.png


### ===============================================
wad_info:
	@./$(BIN) \
		wad \
		info \
		-i ignore/UNPAK/gfx.wad

wad_list:
	@./$(BIN) \
		wad \
		list \
		-i ignore/UNPAK/gfx.wad

wad_extract:
	@./$(BIN) \
		wad \
		extract \
		-i ignore/UNPAK/gfx.wad \
		-o ignore/UNWAD/gfx

wad_create:
	@./$(BIN) \
		wad \
		create \
		-i ignore/UNWAD/gfx/all \
		-o all.wad

### ===============================================
tex_info:
	@./$(BIN) \
		tex \
		info \
		-i ignore/WAD/gfx/*04awater1

tex_decode:
	@./$(BIN) \
		tex \
		decode \
		-i ignore/WAD/gfx/city2_1 \
		-p ignore/WAD/gfx/palette \
		-o ignore/GFX/WAD/city2_1.qoi

tex_encode:
	@./$(BIN) \
		tex \
		encode \
		-i ignore/GFX/WAD/city2_1.qoi \
		-p ignore/WAD/gfx/palette \
		-o ignore/GFX/XWAD/city2_1

tex_decode_me:
	@./$(BIN) \
		tex \
		decode \
		-i ignore/GFX/XWAD/city2_1 \
		-p ignore/WAD/gfx/palette \
		-o ignore/GFX/XWAD/city2_1.qoi
