#include <iostream>
#include <thread>
#include <vector>
#include <windows.h>
using namespace std;
HANDLE sem;
void worker(int id)
{
    WaitForSingleObject(sem, INFINITE);
    cout << "Thread " << id << " acquired resource.\n";
    Sleep(1000);
    cout << "Thread " << id << " releasing resource.\n";
    ReleaseSemaphore(sem, 1, nullptr);
}
int main()
{
    sem = CreateSemaphoreA(nullptr, 2, 2, nullptr);
    vector<thread> ts;
    for (int i = 1; i <= 4; ++i)
        ts.emplace_back(worker, i);
    for (auto &t : ts)
        t.join();
    CloseHandle(sem);
}
