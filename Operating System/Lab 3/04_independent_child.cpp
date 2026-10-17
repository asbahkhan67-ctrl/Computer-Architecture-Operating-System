#include <iostream>
#include <string>
#include <vector>
#include <windows.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc > 1 && string(argv[1]) == "--child") {
        cout << "Independent child process is running. PID = "
             << GetCurrentProcessId() << '\n';
        Sleep(3000);
        cout << "Child kept running after its launcher exited.\n";
        return 0;
    }

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION child{};
    string command = "\"" + string(argv[0]) + "\" --child";
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    if (!CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE,
                        CREATE_NEW_CONSOLE, nullptr, nullptr, &si, &child)) return 1;
    cout << "Launcher PID " << GetCurrentProcessId()
         << " started the child and is exiting.\n";
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return 0;
}
