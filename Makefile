CXX=g++

ifneq ($(DEBUG),)
	CXXFLAGS=-g -Wall -O0 -DDBGPRINT -isystem./WFA-paper -L$./WFA-paper/build -std=c++14 -I./include
else
	CXXFLAGS=-g -Wall -O3 -isystem./WFA-paper -mavx2 -L./WFA-paper/build -std=c++14 -I./include
endif

# TBB settings
TBB_INCLUDE = /usr/include/tbb
TBB_LIB = /usr/lib/x86_64-linux-gnu/libtbb.so
#TBB_LIB = /media/ssd/ngs-data-analysis/code/oneTBB-2019_U5/build/linux_intel64_gcc_cc11_libc2.35_kernel5.15.0_release
TBBFLAGS = -L$(TBB_LIB) -ltbb
ACCLDFLAGS=./WFA-paper/build/libwfa.a -lz #-ltbb

OBJ_DIR=obj
HEADERS=$(wildcard ./include/*.h)
TARGETS=key_gen accalign stats
STATSSRC=src/stats.cpp
CPUSRC=src/rmi.cpp src/reference.cpp src/accalign.cpp src/embedding.cpp src/ksw2_extz2_sse.c src/bseq.c src/index.c src/kthread.c src/kalloc.c src/sketch.c src/misc.c src/options.c src/seed.c
#IDXSRC=index.cpp embedding.cpp bseq.c index.c kthread.c kalloc.c sketch.c misc.c options.c 
IDXSRC=src/key_gen.cpp

.PHONY: WFA-paper all
all: WFA-paper ${TARGETS}

WFA-paper:
	$(MAKE) -C WFA-paper clean all

key_gen: ${IDXSRC} ${HEADERS}
	${CXX} -o $@ ${IDXSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -pthread

accalign: ${CPUSRC} ${HEADERS}
	${CXX} -o $@ ${CPUSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -ldl -pthread

stats: ${STATSSRC} ${HEADERS}
	${CC} -o $@ ${STATSSRC} ${ACCLDFLAGS} ${CFLAGS} -fopenmp

clean:
	$(MAKE) -C WFA-paper clean
	rm ${TARGETS}
