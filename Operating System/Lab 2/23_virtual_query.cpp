#include <iostream>
#include <windows.h>
using namespace std;
int main()
{
    int x = 10;
    MEMORY_BASIC_INFORMATION m{};
    if (VirtualQuery(&x, &m, sizeof(m)))
    {
        cout << "Address: " << m.BaseAddress << "\n"
             << "Region Size: " << m.RegionSize << " bytes\n"
             << "State: " << (m.State == MEM_COMMIT ? "MEM_COMMIT" : "OTHER") << "\n";
    }
}
