#include <iostream>
#include <thread>
using namespace std;
thread_local int localVal = 0;
void run(int n)
{
    localVal += n;
    cout << "Thread ID: " << this_thread::get_id() << " | localVal = " << localVal << "\n";
}
int main()
{
    thread a(run, 10), b(run, 20), c(run, 30);
    a.join();
    b.join();
    c.join();
}
