CXXFLAGS += -std=c++14 -O2 -pedantic -Wall -Wextra -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function

SRC_FILES = src/main.cpp src/perf.cpp

all: build

build:
	mkdir -p bin
	$(CXX) $(CXXFLAGS) $(SRC_FILES) -o bin/scheduler_A7 -DPMC_TYPE=0
	$(CXX) $(CXXFLAGS) $(SRC_FILES) -o bin/scheduler_A15 -DPMC_TYPE=1

