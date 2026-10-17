#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <chrono>
using namespace std;
condition_variable cv;
mutex m;
bool ready = false;
void consumer()
{
    unique_lock<mutex> lock(m);
    cv.wait(lock, []
            { return ready; });
    cout << "Condition met, consumer awakened.\n";
}
void producer()
{
    this_thread::sleep_for(chrono::milliseconds(500));
    {
        lock_guard<mutex> lock(m);
        ready = true;
    }
    cv.notify_one();
}
int main()
{
    thread c(consumer), p(producer);
    c.join();
    p.join();
}
