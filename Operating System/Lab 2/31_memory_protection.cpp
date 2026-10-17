#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    char *p = (char *)VirtualAlloc(nullptr, 4096, MEM_COMMIT, PAGE_READWRITE);
    if (!p)
        return 1;
    p[0] = 'A';
    DWORD old;
    if (!VirtualProtect(p, 4096, PAGE_READONLY, &old))
    {
        VirtualFree(p, 0, MEM_RELEASE);
        return 1;
    }
    __try
    {
        p[0] = 'B';
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        cout << "Hardware memory protection trap caught!\n";
    }
    VirtualFree(p, 0, MEM_RELEASE);
}
