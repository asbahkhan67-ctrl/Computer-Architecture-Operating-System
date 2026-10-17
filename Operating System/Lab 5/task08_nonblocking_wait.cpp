#include <iostream>
#include <thread>
#include <future>
#include <chrono>

using namespace std;

int main() {
    auto done = async(launch::async, [] {
        this_thread::sleep_for(chrono::seconds(3));
    });

    while (done.wait_for(chrono::milliseconds(0)) != future_status::ready) {
        cout << "Parent doing independent work...\n";
        this_thread::sleep_for(chrono::milliseconds(500));
    }
    done.get();
    cout << "Child routine finished.\n";
}
