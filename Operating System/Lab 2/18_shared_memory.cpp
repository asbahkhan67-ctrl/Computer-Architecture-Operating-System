#include <iostream>
#include <cstring>
#include <windows.h>
using namespace std;
int main()
{
    HANDLE h = CreateFileMappingA(INVALID_HANDLE_VALUE, nullptr, PAGE_READWRITE, 0, 256, "Local\\MySharedMem");
    if (!h)
        return 1;
    char *p = (char *)MapViewOfFile(h, FILE_MAP_ALL_ACCESS, 0, 0, 256);
    if (!p)
    {
        CloseHandle(h);
        return 1;
    }
    strcpy_s(p, 256, "Shared memory payload");
    cout << "Data in shared region: " << p << "\n";
    UnmapViewOfFile(p);
    CloseHandle(h);
}
