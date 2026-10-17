#include <iostream>
#include <windows.h>
#include <tlhelp32.h>
using namespace std;
int main()
{
    HANDLE s = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (s == INVALID_HANDLE_VALUE)
        return 1;
    PROCESSENTRY32 pe{};
    pe.dwSize = sizeof(pe);
    int n = 0;
    if (Process32First(s, &pe))
    {
        do
        {
            cout << "PID: " << pe.th32ProcessID << "\t" << pe.szExeFile << "\n";
            if (++n >= 5)
                break;
        } while (Process32Next(s, &pe));
    }
    CloseHandle(s);
}
