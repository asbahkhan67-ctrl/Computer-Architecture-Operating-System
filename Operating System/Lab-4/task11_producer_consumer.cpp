#include <condition_variable>
#include <iostream>
#include <mutex>
#include <queue>
#include <thread>

using namespace std;

int main() {
    queue<int> items;
    mutex queueMutex;
    condition_variable condition;
    const int itemCount = 5;

    thread consumer([&]() {
        for (int i = 0; i < itemCount; ++i) {
            unique_lock<mutex> lock(queueMutex);
            condition.wait(lock, [&]() { return !items.empty(); });
            int item = items.front();
            items.pop();
            lock.unlock();
            cout << "Consumed: " << item << '\n';
        }
    });

    thread producer([&]() {
        for (int item = 1; item <= itemCount; ++item) {
            {
                lock_guard<mutex> lock(queueMutex);
                items.push(item);
                cout << "Produced: " << item << '\n';
            }
            condition.notify_one();
        }
    });

    producer.join();
    consumer.join();
    return 0;
}
