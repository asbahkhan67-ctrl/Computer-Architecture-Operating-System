#include <iostream>
#include <string>
#include <vector>
#include <windows.h>
using namespace std;

bool startChild(const string& executable, const string& arguments, PROCESS_INFORMATION& process) {
    STARTUPINFOA startup{};
    startup.cb = sizeof(startup);
    string command = "\"" + executable + "\" " + arguments;
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    return CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE, 0,
                          nullptr, nullptr, &startup, &process) != 0;
}

int main(int argc, char* argv[]) {
    if (argc == 3 && string(argv[1]) == "--child") {
        cout << "Child Process: PID = " << GetCurrentProcessId()
             << ", Parent PID = " << argv[2] << '\n';
        return 0;
    }

    PROCESS_INFORMATION child{};
    string parentId = to_string(GetCurrentProcessId());
    if (!startChild(argv[0], "--child " + parentId, child)) {
        cerr << "Process creation failed.\n";
        return 1;
    }

    cout << "Parent Process: PID = " << GetCurrentProcessId()
         << ", Created Child PID = " << child.dwProcessId << '\n';
    WaitForSingleObject(child.hProcess, INFINITE);
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return 0;
}
