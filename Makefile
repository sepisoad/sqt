CC = gcc
MAKE = make

LUAJIT = libs/c/luajit/src
LFS = libs/c/lfs
SQT = src

LUAJIT_A = libluajit.a
LFS_O = $(LFS)/lfs.o
SQT_O = $(SQT)/main.o
LIBLUAJIT = $(LUAJIT)/$(LUAJIT_A)
BIN = sqt

DEBUG_FLAGS = -g -O0
RELEASE_FLAGS = -O3
CFLAGS = $(DEBUG_FLAGS)

INC = -I.
LIBSPATH = -L$(LUAJIT)
LIBS = $(LIBSPATH) -l:$(LUAJIT_A) -lm

all: bin

luajit: $(LIBLUAJIT)
	$(MAKE) -C $(LUAJIT)

lfs: $(LFS_O)
	$(CC) $(CFLAGS) -c $(LFS)/lfs.c -o $(LFS_O)

sqt: $(SQTMAIN)
	$(CC) $(CFLAGS) -c $(SQT)/main.c -o $(SQT_O)

bin: luajit lfs sqt
	$(CC) $(CFLAGS) $(LFS_O) $(SQT_O) -o $(BIN) $(INC) $(LIBS)


clean:
	rm -rf UNPAK
	rm -f *.o
	rm -f $(LUAJIT)/*o
	rm -f $(LUAJIT)/host/*o
	rm -f $(LFS)/*.o
	rm -f $(SQT)/*.o
	rm -f $(BIN)

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
		-o ignore/UNLMP/ww_axe_1.qoi

lmp_encode:
	@./$(BIN) \
		lmp \
		encode \
		-i ignore/UNLMP/ww_axe_1.qoi \
		-p ignore/UNPAK/gfx/palette.lmp \
		-o ignore/UNLMP/ww_axe_1.lmp

lmp_decode_me:
	@./$(BIN) \
		lmp \
		decode \
		-i ignore/UNLMP/ww_axe_1.lmp \
		-p ignore/UNPAK/gfx/palette.lmp \
		-o ignore/UNLMP/ww_axe_1_me.qoi


### ===============================================
wad_info:
	@./$(BIN) \
		wad \
		info \
		-i ignore/UNPAK/gfx/all.wad

wad_list:
	@./$(BIN) \
		wad \
		list \
		-i ignore/UNPAK/gfx/all.wad

wad_extract:
	@./$(BIN) \
		wad \
		extract \
		-i ignore/UNPAK/gfx/all.wad \
		-o ignore/UNWAD/gfx/all

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