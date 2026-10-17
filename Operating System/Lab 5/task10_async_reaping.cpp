#include <iostream>
#include <thread>
#include <vector>
#include <future>
#include <chrono>

using namespace std;

int main() {
    vector<future<void>> jobs;
    for (int i = 1; i <= 5; ++i) {
        jobs.push_back(async(launch::async, [i] {
            this_thread::sleep_for(chrono::milliseconds(400 * i));
            cout << "Worker " << i << " finished\n";
        }));
    }
    size_t remaining = jobs.size();
    while (remaining) {
        for (auto& worker : jobs) {
            if (worker.valid() &&
                worker.wait_for(chrono::milliseconds(0)) == future_status::ready) {
                worker.get();
                --remaining;
                cout << "Supervisor observed completion; remaining = "
                     << remaining << '\n';
            }
        }
        this_thread::sleep_for(chrono::milliseconds(100));
    }
}
