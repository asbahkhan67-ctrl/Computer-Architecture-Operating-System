#include <iostream>
#include <thread>
#include <mutex>
using namespace std;

int counter = 0;
mutex counterMutex;
void increment() {
    for (int i = 0; i < 100000; ++i) {
        lock_guard<mutex> lock(counterMutex);
        ++counter;
    }
}

int main() {
    thread first(increment), second(increment);
    first.join();
    second.join();
    cout << "Final counter with Mutex: " << counter << '\n';
    return 0;
}
