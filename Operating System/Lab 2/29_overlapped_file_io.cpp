#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    HANDLE h = CreateFileA("async.bin", GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_FLAG_OVERLAPPED, nullptr);
    if (h == INVALID_HANDLE_VALUE)
        return 1;
    OVERLAPPED o{};
    o.hEvent = CreateEventA(nullptr, TRUE, FALSE, nullptr);
    if (!o.hEvent)
    {
        CloseHandle(h);
        return 1;
    }
    char b[1024] = "Asynchronous file write data packet.";
    WriteFile(h, b, sizeof(b), nullptr, &o);
    cout << "I/O initiated. Doing computation in parallel...\n";
    WaitForSingleObject(o.hEvent, INFINITE);
    cout << "Asynchronous write fully committed.\n";
    CloseHandle(o.hEvent);
    CloseHandle(h);
}
