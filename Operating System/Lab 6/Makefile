CXX := g++
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -pthread -fopenmp
LDFLAGS := -pthread -fopenmp -lm
BIN := bin

TARGETS := \
	$(BIN)/task01 $(BIN)/task02 $(BIN)/task03 $(BIN)/task04 $(BIN)/task05 \
	$(BIN)/task06 $(BIN)/task07 $(BIN)/task08 $(BIN)/task09 $(BIN)/task10 \
	$(BIN)/task11 $(BIN)/task12 $(BIN)/task13 $(BIN)/task14 $(BIN)/task15 \
	$(BIN)/task16 $(BIN)/task17 $(BIN)/task18 $(BIN)/task19 $(BIN)/task20

all: $(BIN) $(TARGETS)

$(BIN):
	mkdir -p $(BIN)

$(BIN)/task01: Task\ 1\ -\ Sequential\ vs\ Parallel\ Array\ Sum.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task02: Task\ 2\ -\ Parallel\ Vector\ Expression.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task03: Task\ 3\ -\ Row-Block\ Matrix\ Multiplication.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task04: Task\ 4\ -\ Parallel\ Maximum\ with\ Reduction.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task05: Task\ 5\ -\ Dot\ Product\ Race\ Condition.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task06: Task\ 6\ -\ Two\ Independent\ Tasks.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task07: Task\ 7\ -\ Producer-Consumer\ with\ Bounded\ Buffer.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task08: Task\ 8\ -\ Three-Stage\ Pipeline.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task09: Task\ 9\ -\ Fork-Join\ with\ Unequal\ Task\ Sizes.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task10: Task\ 10\ -\ Task\ Parallelism\ with\ OpenMP\ Sections.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task11: Task\ 11\ -\ Theoretical\ Speedup\ Calculator.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task12: Task\ 12\ -\ Deliberately\ Serial\ Code.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task13: Task\ 13\ -\ Strong\ Scaling\ Experiment.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task14: Task\ 14\ -\ Amdahl\ vs\ Gustafson.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task15: Task\ 15\ -\ Estimate\ Serial\ Fraction.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task16: Task\ 16\ -\ Minimal\ Cooperative\ User-Thread\ Library.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task17: Task\ 17\ -\ Blocking\ Call\ Starves\ User\ Threads.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task18: Task\ 18\ -\ Cost\ of\ pthread\ Creation\ vs\ User-Level\ Switching.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task19: Task\ 19\ -\ Visualising\ Kernel\ Threads\ via\ proc.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task20: Task\ 20\ -\ M-N\ Multiplexing\ and\ Oversubscription.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

clean:
	rm -rf $(BIN)

.PHONY: all clean
