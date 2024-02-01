CXX=g++

ifneq ($(DEBUG),)
	CXXFLAGS=-g -Wall -O0 -DDBGPRINT -isystem./WFA-paper -L$./WFA-paper/build -std=c++14 -I./include
else
	CXXFLAGS=-g -Wall -O3 -isystem./WFA-paper -mavx2 -L./WFA-paper/build -std=c++14 -I./include
endif

# TBB settings
TBB_INCLUDE = ## your path here ##
TBB_LIB = ## your path here ##
#TBB_INCLUDE = /home/ilaria/oneTBB-2019_U5/include
#TBB_LIB = /home/ilaria/oneTBB-2019_U5/build/linux_intel64_gcc_cc11_libc2.35_kernel5.15.0_release
TBBFLAGS = $(if $(TBB_INCLUDE),-I$(TBB_INCLUDE) ,) $(if $(TBB_LIB),-L$(TBB_LIB) -ltbb,-ltbb)
ACCLDFLAGS=./WFA-paper/build/libwfa.a -lz

OBJ_DIR=obj
HEADERS=$(wildcard ./include/*.h)
TARGETS=key_gen accalign stats
STATSSRC=src/stats.cpp
#LOOKUPSRC=src/rmi.cpp src/reference.cpp src/try_lookup.cpp src/embedding.cpp src/ksw2_extz2_sse.c src/bseq.c src/index.c src/kthread.c src/kalloc.c src/sketch.c src/misc.c src/options.c src/seed.c
CPUSRC=src/rmi.cpp src/reference.cpp src/accalign.cpp src/embedding.cpp src/ksw2_extz2_sse.c src/bseq.c src/index.c src/kthread.c src/kalloc.c src/sketch.c src/misc.c src/options.c src/seed.c
OLD_IDXSRC=src/index.cpp src/embedding.cpp src/bseq.c src/index.c src/kthread.c src/kalloc.c src/sketch.c src/misc.c src/options.c 
IDXSRC=src/key_gen.cpp

.PHONY: all
all: ${TARGETS}

WFA-paper: .wfa
	$(MAKE) -C WFA-paper clean all

.wfa:
	touch .wfa

key_gen: WFA-paper ${IDXSRC} ${HEADERS}
	${CXX} -o $@ ${IDXSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -pthread

accalign: WFA-paper ${CPUSRC} ${HEADERS}
	${CXX} -o $@ ${CPUSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -ldl -pthread

stats: WFA-paper ${STATSSRC} ${HEADERS}
	${CXX} -o $@ ${STATSSRC} ${ACCLDFLAGS} ${CXXFLAGS} -fopenmp

accindex: WFA-paper ${OLD_IDXSRC} ${HEADERS}
	${CXX} -o $@ ${OLD_IDXSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -pthread

#lookup: WFA-paper ${LOOKUPSRC} ${HEADERS}
#	${CXX} -o $@ ${LOOKUPSRC} ${ACCLDFLAGS} ${TBBFLAGS} ${CXXFLAGS} -pthread

clean:
	rm .wfa 
	$(MAKE) -C WFA-paper clean
	rm ${TARGETS}
