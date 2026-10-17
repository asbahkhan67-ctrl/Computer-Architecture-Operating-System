// Detached worker demonstrates independence, but is not a real OS orphan process.
#include <iostream>
#include <thread>
#include <chrono>

using namespace std;

int main() {
    thread([] {
        this_thread::sleep_for(chrono::seconds(2));
        cout << "Detached worker continued after main stopped supervising it.\n";
    }
    ).detach();
    cout << "Main routine ends; wait briefly so the demonstration can print.\n";
    this_thread::sleep_for(chrono::seconds(3));
}
