# powturbo  (c) Copyright 2015-2017
CC ?= gcc
CXX ?= g++
#CC=clang
#CXX=clang++

ifeq ($(OS),Windows_NT)
  UNAME := Windows
CC=gcc
CXX=g++
else
  UNAME := $(shell uname -s)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin FreeBSD GNU/kFreeBSD))
LDFLAGS+= -lrt
endif
endif

ifeq ($(BITSHUFFLE),1)
DEFS+=-DBITSHUFFLE
endif

ifeq ($(BLOSC),1)
DEFS+=-DBLOSC
endif

MARCH=-march=native
#MARCH=-march=broadwell

ifeq ($(AVX2),1)
MARCH+=-mavx2 -mbmi2
else
AVX2=0
endif

CFLAGS=-w -Wall $(DEFS)

all: tpbench

transpose.o: transpose.c
	$(CC) -O3 $(CFLAGS) -falign-loops=32 -c transpose.c -o transpose.o

transpose_sse.o: transpose.c
	$(CC) -O3 $(CFLAGS) -DSSE2_ON -mssse3 -falign-loops=32 -c transpose.c -o transpose_sse.o

transpose_avx2.o: transpose.c
	$(CC) -O3 $(CFLAGS) -DAVX2_ON -march=haswell -mavx2 -falign-loops=32 -c transpose.c -o transpose_avx2.o


OB=transpose.o transpose_sse.o transpose_avx2.o tpbench.o


ifeq ($(BLOSC),1)
LDFLAGS+=-lpthread 
CFLAGS+=-DSHUFFLE_SSE2_ENABLED -DBLOSC 
#-DPREFER_EXTERNAL_LZ4=ON -DHAVE_LZ4 -DHAVE_LZ4HC -Ibitshuffle/lz4
ifeq ($(AVX2),1)
CFLAGS+=-DSHUFFLE_AVX2_ENABLED
OB+=c-blosc/blosc/shuffle-avx2.o c-blosc/blosc/bitshuffle-avx2.o
endif
OB+=c-blosc/blosc/blosc.o c-blosc/blosc/blosclz.o c-blosc/blosc/shuffle.o c-blosc/blosc/shuffle-generic.o c-blosc/blosc/shuffle-sse2.o \
c-blosc/blosc/bitshuffle-generic.o c-blosc/blosc/bitshuffle-sse2.o
else

ifeq ($(BITSHUFFLE),1)
ifeq ($(AVX2),1)
CFLAGS+=-DUSEAVX2
endif
CFLAGS+=-Ibitshuffle/lz4 -DLZ4_ON
OB+=bitshuffle/src/bitshuffle.o bitshuffle/src/iochain.o bitshuffle/src/bitshuffle_core.o
OB+=bitshuffle/lz4/lz4.o
endif

endif

tpbench: $(OB)
	$(CC) $^ $(LDFLAGS) -o tpbench
 
.c.o:
	$(CC) -O3 $(MARCH) $(CFLAGS) $< -c -o $@

clean:
	@find . -type f -name "*\.o" -delete -or -name "*\~" -delete -or -name "core" -delete

cleanw:
	del /S *.o
	del /S *.exe

