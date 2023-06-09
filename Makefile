# Compiler settings
CXX = g++
CXXFLAGS = -std=c++14 -Wall -Wextra -O3 -I./include

# TBB settings
TBB_INCLUDE = /usr/include/tbb
TBB_LIB = /usr/lib/x86_64-linux-gnu/libtbb.so
TBBFLAGS = -L$(TBB_LIB) -ltbb

# Source file and binary file paths
SRC = src/key_gen.cpp src/index_gen.cpp src/rmi.cpp
OBJ = bin/rmi.o
BIN_DIR = bin
BIN = $(BIN_DIR)/key_gen $(BIN_DIR)/index_gen

# Targets
all: $(BIN)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/key_gen: ./src/key_gen.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $< $(TBBFLAGS)

$(BIN_DIR)/index_gen: ./src/index_gen.cpp $(BIN_DIR)/rmi.o | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(TBBFLAGS) -ldl

$(BIN_DIR)/rmi.o: ./src/rmi.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -rf $(BIN_DIR)

.PHONY: all clean