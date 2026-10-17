#include <iostream>
#include <string>
#include <vector>
#include <windows.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc > 1 && string(argv[1]) == "--child") {
        cout << "Child PID: " << GetCurrentProcessId() << " terminating now\n";
        return 0;
    }

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION child{};
    string command = "\"" + string(argv[0]) + "\" --child";
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    if (!CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE, 0,
                        nullptr, nullptr, &si, &child)) return 1;

    WaitForSingleObject(child.hProcess, INFINITE);
    cout << "Child exited; keeping its process handle open for 5 seconds.\n";
    Sleep(5000);
    DWORD code = 0;
    GetExitCodeProcess(child.hProcess, &code);
    cout << "Collected child exit code: " << code << '\n';
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return 0;
}
