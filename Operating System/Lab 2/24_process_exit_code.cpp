#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    STARTUPINFOA si{};
    PROCESS_INFORMATION pi{};
    si.cb = sizeof(si);
    char cmd[] = "cmd.exe /C exit 42";
    if (!CreateProcessA(nullptr, cmd, nullptr, nullptr, FALSE, 0, nullptr, nullptr, &si, &pi))
        return 1;
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    cout << "Child process exited with code: " << code << "\n";
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
}
