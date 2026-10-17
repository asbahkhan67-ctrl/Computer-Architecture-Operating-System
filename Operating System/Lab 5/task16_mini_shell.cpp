// Portable C++ can call system(), but command syntax and shell are OS-dependent.
#include <iostream>
#include <string>
#include <cstdlib>

using namespace std;

int main() {
    string line;
    while (true) {
        cout << "myshell> " << flush;
        if (!getline(cin, line) || line == "exit") break;
        if (line.empty()) continue;
        int code = system(line.c_str());
        cout << "system() returned " << code << '\n';
    }
}
