#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

using namespace std;

int main() {
    int counter = 0;
    mutex counterMutex;
    const int threadCount = 4;
    const int incrementsPerThread = 100000;
    vector<thread> workers;

    for (int worker = 0; worker < threadCount; ++worker) {
        workers.emplace_back([&counter, &counterMutex, incrementsPerThread]() {
            for (int i = 0; i < incrementsPerThread; ++i) {
                lock_guard<mutex> lock(counterMutex);
                ++counter;
            }
        });
    }

    for (thread& worker : workers) {
        worker.join();
    }

    cout << "Final counter value: " << counter << '\n';
    return 0;
}
