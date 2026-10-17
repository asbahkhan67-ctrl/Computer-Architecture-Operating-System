// Nested threads demonstrate bottom-up synchronization in a linear hierarchy.
#include <iostream>
#include <thread>

using namespace std;

int main() {
    thread child([] {
        thread grandchild([] {
            cout << "Grandchild work complete\n";
        });

        grandchild.join();
        cout << "Child: grandchild joined\n";
    });

    child.join();
    cout << "Parent: all descendants completed\n";
}
