CC=g++

ifneq ($(DEBUG),)
	CFLAGS=-g -Wall -pthread -O0 -DDBGPRINT -isystem./WFA-paper -L$./WFA-paper/build -std=c++14
else
	CFLAGS=-g -Wall -pthread -O3 -isystem./WFA-paper -mavx2 -L./WFA-paper/build -std=c++14
endif

ACCLDFLAGS=./WFA-paper/build/libwfa.a -lz -ltbb
TARGETS=accindex accalign
CPUSRC=reference.cpp accalign.cpp embedding.cpp ksw2_extz2_sse.c
IDXSRC=index.cpp embedding.cpp
HEADERS=$(wildcard *.h) 

.PHONY: all
all: ${TARGETS}

.wfa:
	touch .wfa

WFA-paper: .wfa
	$(MAKE) -C WFA-paper clean all

accindex: WFA-paper ${IDXSRC} ${HEADERS}
	${CC} -o $@ ${IDXSRC} ${ACCLDFLAGS} ${CFLAGS} 

accalign: WFA-paper ${CPUSRC} ${HEADERS}
	${CC} -o $@ ${CPUSRC} ${ACCLDFLAGS} ${CFLAGS}

clean:
	rm .wfa
	$(MAKE) -C WFA-paper clean
	rm ${TARGETS}
