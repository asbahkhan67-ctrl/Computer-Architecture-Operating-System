#include <atomic>
#include <chrono>
#include <iostream>
#include <thread>

using namespace std;

int main() {
    atomic<bool> finished{false};

    thread logger([&finished]() {
        for (int message = 1; message <= 5; ++message) {
            cout << "Background logger: message " << message << '\n';
            this_thread::sleep_for(chrono::milliseconds(300));
        }
        finished.store(true);
    });

    logger.detach();
    cout << "Logger detached; main no longer owns a joinable thread handle.\n";

    // Keep shared state alive until the detached worker reports completion.
    while (!finished.load()) {
        this_thread::sleep_for(chrono::milliseconds(50));
    }
    cout << "Background logger finished.\n";
    return 0;
}
