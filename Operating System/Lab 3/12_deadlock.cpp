#include <iostream>
#include <thread>
#include <mutex>
#include <chrono>
#include <atomic>
using namespace std;

mutex lockA, lockB;
atomic<int> ready{0};
void firstWorker() {
    lock_guard<mutex> first(lockA);
    cout << "Thread 1 acquired Lock A, waiting for Lock B...\n" << flush;
    ready.fetch_add(1);
    while (ready.load() < 2) this_thread::yield();
    lock_guard<mutex> second(lockB);
}
void secondWorker() {
    lock_guard<mutex> second(lockB);
    cout << "Thread 2 acquired Lock B, waiting for Lock A...\n" << flush;
    ready.fetch_add(1);
    while (ready.load() < 2) this_thread::yield();
    lock_guard<mutex> first(lockA);
}

int main() {
    thread first(firstWorker), second(secondWorker);
    first.join();
    second.join();
    return 0;
}
