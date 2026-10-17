#include <iostream>
#include <thread>

using namespace std;

void childRoutine() {
    cout << "Child thread is running. Thread ID: " << this_thread::get_id() << '\n';
}

int main() {
    thread child(childRoutine);
    cout << "Main thread is waiting for the child.\n";
    child.join();
    cout << "Child thread has finished.\n";
    return 0;
}
