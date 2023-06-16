CXX=g++

ifneq ($(DEBUG),)
	CXXFLAGS=-g -Wall -pthread -O0 -DDBGPRINT -isystem./WFA-paper -L$./WFA-paper/build -std=c++14 -I./include
else
	CXXFLAGS=-g -Wall -pthread -O3 -isystem./WFA-paper -mavx2 -L./WFA-paper/build -std=c++14 -I./include
endif

# TBB settings
TBB_INCLUDE = /usr/include/tbb
TBB_LIB = /usr/lib/x86_64-linux-gnu/libtbb.so
TBBFLAGS = -L$(TBB_LIB) -ltbb
ACCLDFLAGS=./WFA-paper/build/libwfa.a -lz #-ltbb

OBJ_DIR=obj
HEADERS=$(wildcard ./include/*.h)
TARGETS=key_gen accalign
CPUSRC=src/rmi.cpp src/reference.cpp src/accalign.cpp src/embedding.cpp src/ksw2_extz2_sse.c src/bseq.c src/index.c src/kthread.c src/kalloc.c src/sketch.c src/misc.c src/options.c src/seed.c
#IDXSRC=index.cpp embedding.cpp bseq.c index.c kthread.c kalloc.c sketch.c misc.c options.c 
IDXSRC=src/key_gen.cpp

.PHONY: WFA-paper all
all: WFA-paper ${TARGETS}

WFA-paper:
	$(MAKE) -C WFA-paper clean all

key_gen: ${IDXSRC} ${HEADERS}
	${CXX} -o $@ ${IDXSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} 

accalign: ${CPUSRC} ${HEADERS}
	${CXX} -o $@ ${CPUSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -ldl

clean:
	$(MAKE) -C WFA-paper clean
	rm ${TARGETS}
