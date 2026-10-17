#include <future>
#include <iostream>
#include <thread>
#include <utility>

using namespace std;

int main() {
    promise<int> resultPromise;
    future<int> resultFuture = resultPromise.get_future();

    thread worker([promise = move(resultPromise)]() mutable {
        promise.set_value(42);
    });

    cout << "Waiting for the worker's result...\n";
    cout << "Result received: " << resultFuture.get() << '\n';
    worker.join();
    return 0;
}
