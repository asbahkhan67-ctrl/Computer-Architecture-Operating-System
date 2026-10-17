#include <atomic>
#include <iostream>
#include <thread>
#include <vector>

using namespace std;

int main() {
    atomic<int> counter{0};
    const int threadCount = 4;
    const int incrementsPerThread = 100000;
    vector<thread> workers;

    for (int worker = 0; worker < threadCount; ++worker) {
        workers.emplace_back([&counter, incrementsPerThread]() {
            for (int i = 0; i < incrementsPerThread; ++i) {
                counter.fetch_add(1, memory_order_relaxed);
            }
        });
    }

    for (thread& worker : workers) {
        worker.join();
    }

    cout << "Final atomic counter value: " << counter.load() << '\n';
    return 0;
}
