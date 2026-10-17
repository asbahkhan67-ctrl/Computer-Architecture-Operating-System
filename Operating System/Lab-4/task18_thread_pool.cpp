#include <condition_variable>
#include <functional>
#include <iostream>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>
#include <utility>

using namespace std;

class ThreadPool {
public:
    explicit ThreadPool(size_t workerCount) : stopping_(false) {
        for (size_t i = 0; i < workerCount; ++i) {
            workers_.emplace_back([this]() { workerLoop(); });
        }
    }

    ThreadPool(const ThreadPool&) = delete;
    ThreadPool& operator=(const ThreadPool&) = delete;

    ~ThreadPool() {
        {
            lock_guard<mutex> lock(queueMutex_);
            stopping_ = true;
        }
        condition_.notify_all();
        for (thread& worker : workers_) {
            worker.join();
        }
    }

    void enqueue(function<void()> task) {
        {
            lock_guard<mutex> lock(queueMutex_);
            tasks_.push(move(task));
        }
        condition_.notify_one();
    }

private:
    void workerLoop() {
        while (true) {
            function<void()> task;
            {
                unique_lock<mutex> lock(queueMutex_);
                condition_.wait(lock, [this]() {
                    return stopping_ || !tasks_.empty();
                });

                if (stopping_ && tasks_.empty()) {
                    return;
                }

                task = move(tasks_.front());
                tasks_.pop();
            }
            task();
        }
    }

    vector<thread> workers_;
    queue<function<void()>> tasks_;
    mutex queueMutex_;
    condition_variable condition_;
    bool stopping_;
};

int main() {
    ThreadPool pool(3);
    for (int task = 1; task <= 8; ++task) {
        pool.enqueue([task]() {
            cout << "Pool worker executed task " << task << '\n';
        });
    }
    // The pool destructor drains queued tasks and joins all workers.
    return 0;
}
