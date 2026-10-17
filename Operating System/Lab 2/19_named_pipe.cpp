#include <iostream>
#include <thread>
#include <windows.h>
using namespace std;
void client()
{
    Sleep(500);
    HANDLE h = CreateFileA("\\\\.\\pipe\\TestPipe", GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr);
    if (h != INVALID_HANDLE_VALUE)
    {
        const char msg[] = "Hello through Named Pipe!";
        DWORD n = 0;
        WriteFile(h, msg, sizeof(msg), &n, nullptr);
        CloseHandle(h);
    }
}
int main()
{
    HANDLE s = CreateNamedPipeA("\\\\.\\pipe\\TestPipe", PIPE_ACCESS_INBOUND, PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT, 1, 512, 512, 0, nullptr);
    thread t(client);
    ConnectNamedPipe(s, nullptr);
    char b[128] = {};
    DWORD n = 0;
    ReadFile(s, b, sizeof(b) - 1, &n, nullptr);
    cout << "Server received: " << b << "\n";
    t.join();
    DisconnectNamedPipe(s);
    CloseHandle(s);
}
