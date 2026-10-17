// A promise/future carries a routine's return code, analogous to a normal exit status.
#include <iostream>
#include <thread>
#include <future>

using namespace std;

int main() {
    promise<int> result;
    auto status = result.get_future();
    thread child([r = move(result)]() mutable {
        r.set_value(42);
    });

    child.join();
    cout << "Child routine completed with status: " << status.get() << '\n';
}
