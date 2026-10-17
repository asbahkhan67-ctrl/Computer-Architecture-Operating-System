// Standard C++ threads share memory; separate local copies model independent process state.
#include <iostream>
#include <thread>
#include <chrono>

using namespace std;

int main() {
    int parentCounter = 100;
    thread child([counter = parentCounter]() mutable {
        counter += 50;
        cout << "[Child simulation] counter = " << counter << " address = " << &counter << '\n';
    });

    this_thread::sleep_for(chrono::seconds(1));
    cout << "[Parent] counter = " << parentCounter << " address = " << &parentCounter << '\n';
    child.join();
}
