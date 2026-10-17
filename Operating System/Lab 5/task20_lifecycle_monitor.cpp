#include <chrono>
#include <future>
#include <iostream>
#include <stdexcept>
#include <thread>
#include <vector>

using namespace std;

int main() {
    vector<future<int>> workers;

    workers.push_back(async(launch::async, []() {
        return 0;
    }));
    workers.push_back(async(launch::async, []() {
        return 15;
    }));
    workers.push_back(async(launch::async, []() -> int {
        throw runtime_error("simulated crash");
    }));

    size_t remaining = workers.size();
    while (remaining > 0) {
        for (size_t index = 0; index < workers.size(); ++index) {
            future<int>& worker = workers[index];
            if (!worker.valid() ||
                worker.wait_for(chrono::milliseconds(0)) != future_status::ready) {
                continue;
            }

            try {
                cout << "Harvested worker " << index + 1
                     << " with code " << worker.get() << '\n';
            } catch (const exception& error) {
                cout << "Harvested worker " << index + 1
                     << " failure: " << error.what() << '\n';
            }

            --remaining;
        }

        this_thread::sleep_for(chrono::milliseconds(50));
    }

    return 0;
}
