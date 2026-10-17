#include <chrono>
#include <algorithm>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

using namespace std;

int main() {
    const int philosopherCount = 5;
    vector<mutex> forks(philosopherCount);
    vector<thread> philosophers;

    for (int id = 0; id < philosopherCount; ++id) {
        philosophers.emplace_back([id, &forks, philosopherCount]() {
            int leftFork = id;
            int rightFork = (id + 1) % philosopherCount;
            int firstFork = min(leftFork, rightFork);
            int secondFork = max(leftFork, rightFork);

            unique_lock<mutex> firstLock(forks[firstFork]);
            unique_lock<mutex> secondLock(forks[secondFork]);

            cout << "Philosopher " << id << " is eating with forks "
                 << firstFork << " and " << secondFork << '\n';
            this_thread::sleep_for(chrono::milliseconds(100));
        });
    }

    for (thread& philosopher : philosophers) {
        philosopher.join();
    }
    return 0;
}
