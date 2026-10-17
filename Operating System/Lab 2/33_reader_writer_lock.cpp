#include <iostream>
#include <thread>
#include <shared_mutex>
#include <mutex>
using namespace std;
shared_mutex rw_lock;
int sharedData = 100;
void reader(int id)
{
    shared_lock<shared_mutex> lock(rw_lock);
    cout << "Reader " << id << " read value: " << sharedData << "\n";
}
void writer(int v)
{
    unique_lock<shared_mutex> lock(rw_lock);
    sharedData = v;
    cout << "Writer updated value to: " << sharedData << "\n";
}
int main()
{
    thread r1(reader, 1), r2(reader, 2), w(writer, 200), r3(reader, 3);
    r1.join();
    r2.join();
    w.join();
    r3.join();
}
