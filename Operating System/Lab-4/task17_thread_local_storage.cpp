#include <iostream>
#include <thread>
#include <vector>

using namespace std;

thread_local int transactionId = 0;

void worker(int workerNumber) {
    transactionId += workerNumber;
    cout << "Worker " << workerNumber << " has thread-local value "
         << transactionId << " at address " << &transactionId << '\n';
}

int main() {
    vector<thread> workers;
    for (int workerNumber = 1; workerNumber <= 3; ++workerNumber) {
        workers.emplace_back(worker, workerNumber);
    }

    for (thread& workerThread : workers) {
        workerThread.join();
    }
    return 0;
}
