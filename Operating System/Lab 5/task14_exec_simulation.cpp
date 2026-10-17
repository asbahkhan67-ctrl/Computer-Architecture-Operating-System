// Standard C++ has no exec-family process-image replacement function.
#include <iostream>

using namespace std;

int main() {
    cout << "POSIX exec would replace this process image. Standard C++ has no portable equivalent.\n";
    cout << "A platform-specific launcher(CreateProcess/posix_spawn) is required to run another program.\n";
}
