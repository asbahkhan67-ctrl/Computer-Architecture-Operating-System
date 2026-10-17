#include <iostream>
#include <cstring>
#include <windows.h>
using namespace std;

int main() {
    HANDLE mapping = CreateFileMappingA(INVALID_HANDLE_VALUE, nullptr,
        PAGE_READWRITE, 0, 4096, nullptr);
    if (!mapping) return 1;

    int* original = static_cast<int*>(MapViewOfFile(
        mapping, FILE_MAP_ALL_ACCESS, 0, 0, 4096));
    int* copy = static_cast<int*>(MapViewOfFile(
        mapping, FILE_MAP_COPY, 0, 0, 4096));
    if (!original || !copy) {
        if (original) UnmapViewOfFile(original);
        if (copy) UnmapViewOfFile(copy);
        CloseHandle(mapping);
        return 1;
    }

    original[0] = 100;
    cout << "Before private write: original = " << original[0]
         << ", copy = " << copy[0] << '\n';
    copy[0] += 50;
    cout << "After private write: original = " << original[0]
         << ", copy = " << copy[0] << '\n';

    UnmapViewOfFile(copy);
    UnmapViewOfFile(original);
    CloseHandle(mapping);
    return 0;
}
