// Futures automatically manage completion state; there is no POSIX zombie table here.
#include <iostream>
#include <thread>
#include <future>
#include <chrono>

using namespace std;

int main() {
    auto child = async(launch::async, [] {
        cout << "Worker completes.\n";
    });

    this_thread::sleep_for(chrono::seconds(2));
    child.get();
    cout << "Completion consumed and resources released by normal C++ object lifetime.\n";
}
