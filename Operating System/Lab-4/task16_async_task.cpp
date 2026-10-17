#include <future>
#include <chrono>
#include <iostream>
#include <thread>

using namespace std;

int heavyCalculation(int value) {
    this_thread::sleep_for(chrono::milliseconds(500));
    return value * value;
}

int main() {
    future<int> result = async(launch::async, heavyCalculation, 12);
    cout << "Main thread performs other work while calculation runs.\n";
    cout << "Calculation result: " << result.get() << '\n';
    return 0;
}
