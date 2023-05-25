# Compiler settings
CXX = g++
CXXFLAGS = -std=c++14 -Wall -Wextra -O3

# TBB settings
TBB_INCLUDE = /usr/include/tbb
TBB_LIB = /usr/lib/x86_64-linux-gnu/libtbb.so

# Source file and binary file paths
SRC_DIR = src
SRC = $(SRC_DIR)/key_gen.cpp
BIN_DIR = bin
BIN = $(BIN_DIR)/key_gen

# Targets
all: $(BIN)

$(BIN): $(SRC) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $< -L$(TBB_PATH)/lib -ltbb

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BIN_DIR)

.PHONY: all clean
