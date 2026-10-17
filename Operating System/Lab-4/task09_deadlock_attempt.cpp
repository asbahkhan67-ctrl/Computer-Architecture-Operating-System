// Demonstrates circular-wait pressure without leaving the program deadlocked.
#include <chrono>
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <thread>

using namespace std;

int main() {
    timed_mutex lockA;
    timed_mutex lockB;
    mutex startMutex;
    condition_variable startCondition;
    int readyWorkers = 0;
    bool startSecondLockAttempt = false;

    auto meetAtSecondLock = [&]() {
        unique_lock<mutex> lock(startMutex);
        ++readyWorkers;
        if (readyWorkers == 2) {
            startSecondLockAttempt = true;
            startCondition.notify_all();
        } else {
            startCondition.wait(lock, [&]() { return startSecondLockAttempt; });
        }
    };

    thread first([&]() {
        lock_guard<timed_mutex> firstLock(lockA);
        cout << "Thread 1 holds Lock A.\n";
        meetAtSecondLock();
        if (lockB.try_lock_for(chrono::milliseconds(100))) {
            lockB.unlock();
        } else {
            cout << "Thread 1 timed out waiting for Lock B.\n";
        }
    });

    thread second([&]() {
        lock_guard<timed_mutex> secondLock(lockB);
        cout << "Thread 2 holds Lock B.\n";
        meetAtSecondLock();
        if (lockA.try_lock_for(chrono::milliseconds(100))) {
            lockA.unlock();
        } else {
            cout << "Thread 2 timed out waiting for Lock A.\n";
        }
    });

    first.join();
    second.join();
    cout << "Timed locking exposed the circular wait and allowed recovery.\n";
    return 0;
}
