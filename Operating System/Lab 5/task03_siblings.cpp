// Two sibling threads are created directly by main.
#include <iostream>
#include <thread>

using namespace std;

int main() {
    thread a([] {
        cout << "First sibling thread: " << this_thread::get_id() << '\n';
    });

    thread b([] {
        cout << "Second sibling thread: " << this_thread::get_id() << '\n';
    });

    a.join();
    b.join();
}
