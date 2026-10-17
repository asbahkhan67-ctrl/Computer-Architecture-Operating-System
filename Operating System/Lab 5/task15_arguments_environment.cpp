#include <iostream>
#include <cstdlib>

using namespace std;

int main(int argc, char* argv[]) {
    cout << "Arguments received: ";
    for (int i = 1; i<argc; ++i) cout << argv[i] << ' ';
    cout << "\nLAB_MODULE = " << (getenv("LAB_MODULE")?getenv("LAB_MODULE"):"(unset)") << "\nSEM = " << (getenv("SEM")?getenv("SEM"):"(unset)") << '\n';
}
