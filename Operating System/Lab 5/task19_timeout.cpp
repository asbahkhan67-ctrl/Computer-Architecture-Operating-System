// Standard C++ cannot safely kill an arbitrary thread; use cooperative cancellation.
#include <iostream>
#include <thread>
#include <atomic>
#include <chrono>

using namespace std;

int main() {
    atomic<bool> stop{
        false
    }
    ;
    thread worker([&] {
        unsigned long long work = 0;
        while (!stop.load(memory_order_relaxed))++work;
        cout << "Worker stopped; iterations = " << work << '\n';
    });

    this_thread::sleep_for(chrono::seconds(3));
    cout << "Timeout reached; requesting cooperative stop.\n";
    stop = true;
    worker.join();
}
