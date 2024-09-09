CC = gcc
DEBUG_FLAGS = -g -o0
RELEASE_FLAGS = -O3
CFLAGS = $(DEBUG_FLAGS)
DEFS = -DSPNG_USE_MINIZ
LIBS = -llua5.4
INC = -I. 
BIN = qtools

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

# debug only targets
unpak:
	@./$(BIN) \
		unpak \
		/home/sepi/Projects/internet/games/quake/game/id1/pak0.pak \
		ignore/UNPAK

unlmp:
	@./$(BIN) \
		unlmp \
		ignore/UNPAK/gfx/bigbox.lmp \
		ignore/UNPAK/gfx/palette.lmp \
		ignore/UNLMP/bigbox.png