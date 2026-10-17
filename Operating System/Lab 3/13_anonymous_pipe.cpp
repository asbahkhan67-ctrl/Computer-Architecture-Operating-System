#include <iostream>
#include <string>
#include <vector>
#include <cstdint>
#include <windows.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc > 2 && string(argv[1]) == "--pipe-child") {
        HANDLE readPipe = reinterpret_cast<HANDLE>(
            static_cast<uintptr_t>(stoull(argv[2])));
        char buffer[128] = {};
        DWORD bytesRead = 0;
        if (ReadFile(readPipe, buffer, sizeof(buffer) - 1, &bytesRead, nullptr))
            cout << "Child read from pipe: " << buffer << '\n';
        CloseHandle(readPipe);
        return 0;
    }

    SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE};
    HANDLE readPipe = nullptr, writePipe = nullptr;
    if (!CreatePipe(&readPipe, &writePipe, &security, 0)) return 1;
    SetHandleInformation(writePipe, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION child{};
    string args = "--pipe-child " + to_string(reinterpret_cast<uintptr_t>(readPipe));
    string command = "\"" + string(argv[0]) + "\" " + args;
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    if (!CreateProcessA(nullptr, writable.data(), nullptr, nullptr, TRUE, 0,
                        nullptr, nullptr, &si, &child)) return 1;

    CloseHandle(readPipe);
    const char message[] = "Hello Child from Windows Pipe";
    DWORD bytesWritten = 0;
    WriteFile(writePipe, message, sizeof(message), &bytesWritten, nullptr);
    CloseHandle(writePipe);
    WaitForSingleObject(child.hProcess, INFINITE);
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return 0;
}
