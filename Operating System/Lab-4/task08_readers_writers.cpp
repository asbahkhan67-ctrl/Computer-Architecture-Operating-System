#include <iostream>
#include <mutex>
#include <shared_mutex>
#include <thread>
#include <vector>

using namespace std;

int main() {
    shared_mutex dataMutex;
    int sharedData = 0;
    vector<thread> workers;

    for (int reader = 1; reader <= 3; ++reader) {
        workers.emplace_back([reader, &dataMutex, &sharedData]() {
            shared_lock<shared_mutex> lock(dataMutex);
            cout << "Reader " << reader << " reads value " << sharedData << '\n';
        });
    }

    workers.emplace_back([&dataMutex, &sharedData]() {
        unique_lock<shared_mutex> lock(dataMutex);
        ++sharedData;
        cout << "Writer updates value to " << sharedData << '\n';
    });

    for (thread& worker : workers) {
        worker.join();
    }
    return 0;
}
