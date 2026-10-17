#include <iostream>
#include <thread>
#include <shared_mutex>
#include <mutex>
using namespace std;

int sharedData = 0;
shared_mutex dataMutex;
void reader(int id) {
    shared_lock<shared_mutex> lock(dataMutex);
    cout << "Reader " << id << " read value: " << sharedData << '\n';
}
void writer(int id, int value) {
    unique_lock<shared_mutex> lock(dataMutex);
    sharedData = value;
    cout << "Writer " << id << " updated value to: " << sharedData << '\n';
}

int main() {
    writer(1, 42);
    thread first(reader, 1), second(reader, 2);
    first.join();
    second.join();
    writer(2, 99);
    reader(3);
    return 0;
}
