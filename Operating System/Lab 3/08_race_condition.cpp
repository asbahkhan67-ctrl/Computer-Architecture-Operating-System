#include <iostream>
#include <thread>
#include <atomic>
using namespace std;

atomic<int> counter{0};
void increment() {
    for (int i = 0; i < 100000; ++i) {
        int value = counter.load();
        this_thread::yield();
        counter.store(value + 1);
    }
}

int main() {
    thread first(increment), second(increment);
    first.join();
    second.join();
    cout << "Expected: 200000 | Actual counter: " << counter.load() << '\n';
    return 0;
}
