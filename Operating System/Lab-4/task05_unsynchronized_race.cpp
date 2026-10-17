// This exercise intentionally demonstrates a data race. In C++, a data race
// has undefined behavior. Use task06 for the safe, mutex-protected version.
#include <iostream>
#include <thread>
#include <vector>

using namespace std;

int main() {
    int counter = 0;
    const int threadCount = 4;
    const int incrementsPerThread = 100000;
    vector<thread> workers;

    for (int worker = 0; worker < threadCount; ++worker) {
        workers.emplace_back([&counter, incrementsPerThread]() {
            for (int i = 0; i < incrementsPerThread; ++i) {
                ++counter; // Deliberate unsynchronized read-modify-write.
            }
        });
    }

    for (thread& worker : workers) {
        worker.join();
    }

    cout << "Counter (undefined result because of the intentional data race): "
         << counter << '\n';
    return 0;
}
