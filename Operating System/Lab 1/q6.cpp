#include <iostream>
#include <stdlib.h>
using namespace std;

int main() {
    cout << "Current user is: " << getenv("USERNAME") << endl;
    return 0;
}