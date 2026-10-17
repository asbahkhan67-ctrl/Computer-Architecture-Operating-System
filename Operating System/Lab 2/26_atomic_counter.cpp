#include <iostream>
#include <thread>
#include <vector>
#include <atomic>
using namespace std;
atomic<long> counter{0};
void increment()
{
    for (int i = 0; i < 100000; ++i)
        counter.fetch_add(1, memory_order_relaxed);
}
int main()
{
    vector<thread> ts;
    for (int i = 0; i < 4; ++i)
        ts.emplace_back(increment);
    for (auto &t : ts)
        t.join();
    cout << "Final Atomic Counter: " << counter << "\n";
}
