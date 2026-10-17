#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    void *p = VirtualAlloc(nullptr, 1024 * 1024, MEM_RESERVE, PAGE_NOACCESS);
    if (!p)
        return 1;
    cout << "Reserved 1 MB address space at: " << p << "\n";
    int *page = (int *)VirtualAlloc(p, 4096, MEM_COMMIT, PAGE_READWRITE);
    if (!page)
    {
        VirtualFree(p, 0, MEM_RELEASE);
        return 1;
    }
    page[0] = 42;
    cout << "Committed memory value: " << page[0] << "\n";
    VirtualFree(p, 0, MEM_RELEASE);
}
