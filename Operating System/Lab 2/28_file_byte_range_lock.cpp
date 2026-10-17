#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    HANDLE h = CreateFileA("guard_test.txt", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, CREATE_ALWAYS, 0, nullptr);
    if (h == INVALID_HANDLE_VALUE)
        return 1;
    if (LockFile(h, 0, 0, 100, 0))
    {
        cout << "Byte range [0-100] locked successfully.\n";
        UnlockFile(h, 0, 0, 100, 0);
        cout << "Byte range unlocked.\n";
    }
    CloseHandle(h);
}
