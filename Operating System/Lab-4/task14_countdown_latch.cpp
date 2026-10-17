// A one-use countdown gate implemented with C++17 synchronization tools.
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

using namespace std;

class CountdownLatch {
public:
    explicit CountdownLatch(int count) : count_(count) {}

    void wait() {
        unique_lock<mutex> lock(mutex_);
        condition_.wait(lock, [&]() { return count_ == 0; });
    }

    void countDown() {
        lock_guard<mutex> lock(mutex_);
        if (--count_ == 0) {
            condition_.notify_all();
        }
    }

private:
    mutex mutex_;
    condition_variable condition_;
    int count_;
};

int main() {
    const int workerCount = 4;
    CountdownLatch startGate(1);
    vector<thread> workers;

    for (int worker = 1; worker <= workerCount; ++worker) {
        workers.emplace_back([worker, &startGate]() {
            cout << "Worker " << worker << " is ready.\n";
            startGate.wait();
            cout << "Worker " << worker << " started its work.\n";
        });
    }

    cout << "Coordinator prepares shared data. Releasing workers.\n";
    startGate.countDown();

    for (thread& worker : workers) {
        worker.join();
    }
    return 0;
}
