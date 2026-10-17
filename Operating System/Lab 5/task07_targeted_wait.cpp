#include <iostream>
#include <thread>
#include <future>
#include <chrono>

using namespace std;

int main() {
    auto work = [](int ms, int code) {
        this_thread::sleep_for(chrono::milliseconds(ms));
        return code;
    }
    ;
    auto a = async(launch::async, work, 4000, 10);
    auto b = async(launch::async, work, 1000, 20);
    cout << "Waiting specifically for Child A...\n";
    cout << "Child A completed with status " << a.get() << '\n';
    cout << "Child B completed with status " << b.get() << '\n';
}
