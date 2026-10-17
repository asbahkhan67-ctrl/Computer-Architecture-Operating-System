#include <functional>
#include <iostream>
#include <thread>

using namespace std;

void worker(int value, int& reference) {
    value += 10;
    reference += 10;
    cout << "Inside worker: value copy = " << value
         << ", referenced value = " << reference << '\n';
}

int main() {
    int value = 5;
    int referenceValue = 5;

    thread child(worker, value, ref(referenceValue));
    child.join();

    cout << "After join: original value = " << value
         << ", referenced value = " << referenceValue << '\n';
    return 0;
}
