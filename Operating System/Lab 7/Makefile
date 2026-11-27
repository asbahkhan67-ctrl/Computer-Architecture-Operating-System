CXX := g++
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -pthread
LDFLAGS := -pthread -lm
BIN := bin

TARGETS := \
	$(BIN)/task01 $(BIN)/task02 $(BIN)/task03 $(BIN)/task04 $(BIN)/task05 \
	$(BIN)/task06 $(BIN)/task07 $(BIN)/task08 $(BIN)/task09 $(BIN)/task10 \
	$(BIN)/task11 $(BIN)/task12 $(BIN)/task13 $(BIN)/task14 $(BIN)/task15 \
	$(BIN)/task16 $(BIN)/task17 $(BIN)/task18 $(BIN)/task19 $(BIN)/task20

all: $(BIN) $(TARGETS)

$(BIN):
	mkdir -p $(BIN)

$(BIN)/task01: Task\ 1\ -\ Basic\ POSIX\ Thread\ Lifecycle.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task02: Task\ 2\ -\ Kernel\ Task\ ID\ vs\ POSIX\ Thread\ Handle.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task03: Task\ 3\ -\ Direct\ Low-Level\ Thread\ Creation\ via\ clone.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task04: Task\ 4\ -\ Multi-Core\ Hardware\ Parallelism\ and\ CPU\ Pinning.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task05: Task\ 5\ -\ Futex-Based\ Mutex\ vs\ Spinlock.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task06: Task\ 6\ -\ Kernel\ Coordination\ via\ Condition\ Variables.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task07: Task\ 7\ -\ Thread-Specific\ Data\ and\ TLS.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task08: Task\ 8\ -\ Cooperative\ Context\ Switching\ with\ setjmp\ longjmp.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task09: Task\ 9\ -\ Fiber\ Creation\ and\ Stack\ Allocation\ with\ ucontext.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task10: Task\ 10\ -\ Round-Robin\ Cooperative\ ULT\ Scheduler.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task11: Task\ 11\ -\ Preemptive\ ULT\ Scheduler\ Using\ POSIX\ Interval\ Timers.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task12: Task\ 12\ -\ User-Level\ Mutex\ Primitives.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task13: Task\ 13\ -\ User-Space\ Producer-Consumer\ Pipeline.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task14: Task\ 14\ -\ Demonstrating\ the\ 1-N\ Blocking\ IO\ Pitfall.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task15: Task\ 15\ -\ Non-Blocking\ User-Space\ IO\ with\ Event\ Polling.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task16: Task\ 16\ -\ Context\ Switching\ Latency\ Benchmark.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task17: Task\ 17\ -\ Thread\ Creation\ and\ Scalability\ Limits.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task18: Task\ 18\ -\ Multi-Core\ Scalability\ on\ CPU-Bound\ Workloads.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task19: Task\ 19\ -\ Implementing\ a\ Hybrid\ M-N\ Threading\ Runtime.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

$(BIN)/task20: Task\ 20\ -\ Asynchronous\ Signal\ Routing\ in\ ULT\ vs\ KLT.cpp
	$(CXX) $(CXXFLAGS) "$<" -o "$@" $(LDFLAGS)

clean:
	rm -rf $(BIN)

.PHONY: all clean
