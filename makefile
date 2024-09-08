CC = gcc
DEBUG_FLAGS = -g -o0
RELEASE_FLAGS = -O3
CFLAGS = $(DEBUG_FLAGS)
LIBS = -llua5.4
INC = -I. 
BIN = qtools

SRC = \
	libs/c/foo/foo.c \
	libs/c/lfs/lfs.c \
	src/main.c

build: 
	$(CC) $(CFLAGS) $(SRC) -o $(BIN) $(LIBS) $(INC)

unpak:
	@./$(BIN) "/home/sepi/Projects/internet/games/quake/game/id1/pak0.pak" "/home/sepi/Projects/sepi/quake-tools/UNPAK"