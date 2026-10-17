// A supervisor explicitly joins its worker tree; standard C++ has no subreaper facility.
#include <iostream>
#include <thread>

using namespace std;

int main() {
    thread supervisor([] {
        thread descendant([] {
            cout << "Descendant routine completed\n";
        });

        descendant.join();
        cout << "Supervisor collected descendant completion\n";
    });

    supervisor.join();
    cout << "Top-level routine completed\n";
}
