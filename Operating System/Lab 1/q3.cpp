#include <iostream>
#include <windows.h>
using namespace std;

int main() {
    cout << "My unique Process ID is: " << GetCurrentProcessId() << endl;
    return 0;
}
