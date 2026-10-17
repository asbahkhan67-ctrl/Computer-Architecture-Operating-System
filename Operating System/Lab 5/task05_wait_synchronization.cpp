#include <iostream>
#include <thread>
#include <chrono>

using namespace std;

int main() {
    thread child([] {
        for (int i = 1; i <= 5; ++i) {
            cout << "Child working... step " << i << '\n';
            this_thread::sleep_for(chrono::milliseconds(500));
        }
    });

    cout << "Parent waiting for child completion...\n";
    child.join();
    cout << "Parent resumed: child routine completed.\n";
}
