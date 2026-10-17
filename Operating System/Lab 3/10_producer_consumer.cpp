#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
using namespace std;

queue<int> buffer;
const size_t capacity = 3;
mutex bufferMutex;
condition_variable canProduce, canConsume;

void producer() {
    for (int item = 1; item <= 5; ++item) {
        unique_lock<mutex> lock(bufferMutex);
        canProduce.wait(lock, [] { return buffer.size() < capacity; });
        buffer.push(item);
        cout << "Produced: " << item << '\n';
        lock.unlock();
        canConsume.notify_one();
    }
}

void consumer() {
    for (int i = 0; i < 5; ++i) {
        unique_lock<mutex> lock(bufferMutex);
        canConsume.wait(lock, [] { return !buffer.empty(); });
        int item = buffer.front();
        buffer.pop();
        cout << "Consumed: " << item << '\n';
        lock.unlock();
        canProduce.notify_one();
    }
}

int main() {
    thread makeItems(producer), useItems(consumer);
    makeItems.join();
    useItems.join();
    return 0;
}
