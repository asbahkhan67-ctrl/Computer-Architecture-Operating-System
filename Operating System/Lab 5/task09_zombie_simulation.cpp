// A real zombie is an OS process state and cannot be created in standard C++.
#include <iostream>
#include <thread>
#include <chrono>
#include <future>

using namespace std;

int main() {
    promise<void> ended;
    auto future = ended.get_future();
    thread child([p = move(ended)]() mutable {
        cout << "Child routine exits.\n";
        p.set_value();
    });

    cout << "Parent delays collecting completion for 5 seconds(zombie-state simulation only).\n";
    this_thread::sleep_for(chrono::seconds(5));
    future.wait();
    child.join();
    cout << "Completion collected; no actual zombie process was created.\n";
}
