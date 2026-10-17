#include <iostream>
#include <string>
#include <vector>
#include <windows.h>
using namespace std;

bool launch(const string& exe, const string& args, PROCESS_INFORMATION& pi) {
    STARTUPINFOA si{};
    si.cb = sizeof(si);
    string command = "\"" + exe + "\" " + args;
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    return CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE, 0,
                          nullptr, nullptr, &si, &pi) != 0;
}

int main(int argc, char* argv[]) {
    if (argc > 1 && string(argv[1]) == "--child") {
        cout << "Child executing task...\n";
        Sleep(2000);
        cout << "Child exiting with code 42\n";
        return 42;
    }

    PROCESS_INFORMATION child{};
    if (!launch(argv[0], "--child", child)) return 1;
    cout << "Parent waiting for child...\n";
    WaitForSingleObject(child.hProcess, INFINITE);
    DWORD exitCode = 0;
    GetExitCodeProcess(child.hProcess, &exitCode);
    cout << "Parent: Child terminated with exit status " << exitCode << '\n';
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return 0;
}
