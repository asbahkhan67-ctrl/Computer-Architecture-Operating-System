// A reusable barrier implemented with C++17 mutexes and condition variables.
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

using namespace std;

class CyclicBarrier {
public:
    explicit CyclicBarrier(size_t participants)
        : participantCount_(participants), waiting_(0), generation_(0) {}

    void arriveAndWait() {
        unique_lock<mutex> lock(mutex_);
        size_t currentGeneration = generation_;

        if (++waiting_ == participantCount_) {
            waiting_ = 0;
            ++generation_;
            condition_.notify_all();
        } else {
            condition_.wait(lock, [&]() { return generation_ != currentGeneration; });
        }
    }

private:
    const size_t participantCount_;
    size_t waiting_;
    size_t generation_;
    mutex mutex_;
    condition_variable condition_;
};

int main() {
    const int workerCount = 4;
    CyclicBarrier barrier(workerCount);
    vector<thread> workers;

    for (int worker = 1; worker <= workerCount; ++worker) {
        workers.emplace_back([worker, &barrier]() {
            cout << "Worker " << worker << " finished phase 1.\n";
            barrier.arriveAndWait();
            cout << "Worker " << worker << " started phase 2.\n";
        });
    }

    for (thread& worker : workers) {
        worker.join();
    }
    return 0;
}
