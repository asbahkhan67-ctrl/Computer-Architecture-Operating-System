// C++17 implementation of a counting semaphore using a mutex and condition variable.
#include <condition_variable>
#include <chrono>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

using namespace std;

class CountingSemaphore {
public:
    explicit CountingSemaphore(int permits) : permits_(permits) {}

    void acquire() {
        unique_lock<mutex> lock(mutex_);
        condition_.wait(lock, [&]() { return permits_ > 0; });
        --permits_;
    }

    void release() {
        {
            lock_guard<mutex> lock(mutex_);
            ++permits_;
        }
        condition_.notify_one();
    }

private:
    mutex mutex_;
    condition_variable condition_;
    int permits_;
};

int main() {
    CountingSemaphore semaphore(3);
    vector<thread> tasks;

    for (int task = 1; task <= 8; ++task) {
        tasks.emplace_back([task, &semaphore]() {
            semaphore.acquire();
            cout << "Task " << task << " entered the limited resource.\n";
            this_thread::sleep_for(chrono::milliseconds(200));
            cout << "Task " << task << " leaving the limited resource.\n";
            semaphore.release();
        });
    }

    for (thread& task : tasks) {
        task.join();
    }
    return 0;
}
