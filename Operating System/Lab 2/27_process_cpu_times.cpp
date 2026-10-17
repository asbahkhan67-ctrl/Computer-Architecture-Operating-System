#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    volatile long count = 0;
    for (long i = 0; i < 200000000; ++i)
        count += i;
    FILETIME c, e, k, u;
    GetProcessTimes(GetCurrentProcess(), &c, &e, &k, &u);
    ULARGE_INTEGER kt{}, ut{};
    kt.LowPart = k.dwLowDateTime;
    kt.HighPart = k.dwHighDateTime;
    ut.LowPart = u.dwLowDateTime;
    ut.HighPart = u.dwHighDateTime;
    cout << "Kernel Time (Ring 0): " << kt.QuadPart / 10000 << " ms\n"
         << "User Time (Ring 3): " << ut.QuadPart / 10000 << " ms\n";
}
