#include <atomic>
#include <chrono>
#include <iostream>
#include <thread>

using namespace std;

int main() {
    atomic<bool> stopRequested{false};

    thread worker([&stopRequested]() {
        unsigned long long workCount = 0;
        while (!stopRequested.load()) {
            ++workCount;
        }
        cout << "Worker received stop request and cleaned up. Work count: "
             << workCount << '\n';
    });

    this_thread::sleep_for(chrono::seconds(1));
    cout << "Manager requests cooperative shutdown.\n";
    stopRequested.store(true);
    worker.join();
    return 0;
}
