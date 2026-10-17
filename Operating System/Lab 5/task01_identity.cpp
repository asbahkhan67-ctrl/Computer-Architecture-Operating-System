// Portable simulation of fork identity branching. Threads share a process, so IDs are thread IDs.
#include <iostream>
#include <thread>
#include <functional>

using namespace std;

int main() {
    auto parent = this_thread::get_id();
    thread child([parent] {
        cout << "Child thread: " << this_thread::get_id() << " | Parent thread: " << parent << '\n';
    });

    cout << "Parent thread: " << parent << " | Child thread created\n";
    child.join();
}
