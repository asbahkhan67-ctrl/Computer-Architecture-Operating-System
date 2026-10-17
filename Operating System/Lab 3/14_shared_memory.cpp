#include <iostream>
#include <string>
#include <vector>
#include <cstring>
#include <windows.h>
using namespace std;

int main(int argc, char* argv[]) {
    const char* name = "Local\\Lab3SharedMemory";
    if (argc > 1 && string(argv[1]) == "--read-memory") {
        HANDLE mapping = OpenFileMappingA(FILE_MAP_READ, FALSE, name);
        if (!mapping) return 1;
        const char* view = static_cast<const char*>(
            MapViewOfFile(mapping, FILE_MAP_READ, 0, 0, 1024));
        if (!view) { CloseHandle(mapping); return 1; }
        cout << "Child read from shared memory: " << view << '\n';
        UnmapViewOfFile(view);
        CloseHandle(mapping);
        return 0;
    }

    HANDLE mapping = CreateFileMappingA(INVALID_HANDLE_VALUE, nullptr,
        PAGE_READWRITE, 0, 1024, name);
    if (!mapping) return 1;
    char* view = static_cast<char*>(MapViewOfFile(
        mapping, FILE_MAP_ALL_ACCESS, 0, 0, 1024));
    if (!view) { CloseHandle(mapping); return 1; }
    const char message[] = "OS Shared Memory Payload";
    memcpy(view, message, sizeof(message));

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION child{};
    string command = "\"" + string(argv[0]) + "\" --read-memory";
    vector<char> writable(command.begin(), command.end());
    writable.push_back('\0');
    if (!CreateProcessA(nullptr, writable.data(), nullptr, nullptr, FALSE, 0,
                        nullptr, nullptr, &si, &child)) return 1;
    WaitForSingleObject(child.hProcess, INFINITE);
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    UnmapViewOfFile(view);
    CloseHandle(mapping);
    return 0;
}
