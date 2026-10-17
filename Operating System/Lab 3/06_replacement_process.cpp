#include <iostream>
#include <string>
#include <vector>
#include <windows.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc > 1 && string(argv[1]) == "--replacement") {
        cout << "Replacement program is running in a new process.\n";
        return 0;
    }

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION replacement{};
    string command = "\"" + string(argv[0]) + "\" --replacement";
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    if (!CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE, 0,
                        nullptr, nullptr, &si, &replacement)) return 1;
    WaitForSingleObject(replacement.hProcess, INFINITE);
    CloseHandle(replacement.hThread);
    CloseHandle(replacement.hProcess);
    cout << "Parent waited for the replacement process.\n";
    return 0;
}
