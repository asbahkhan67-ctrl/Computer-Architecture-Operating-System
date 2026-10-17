#include <iostream>
#include <thread>
#include <windows.h>
using namespace std;
void worker()
{
    if (SetThreadAffinityMask(GetCurrentThread(), 1))
        cout << "Thread successfully bound to Core 0.\n";
}
int main()
{
    cout << "Available hardware cores: " << thread::hardware_concurrency() << "\n";
    thread t(worker);
    t.join();
}
