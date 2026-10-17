#include <iostream>
#include <fstream>
#include <thread>
#include <mutex>

using namespace std;

int main() {
    mutex m;
    ofstream file("log.txt", ios::trunc);
    if (!file) {
        cerr << "Could not open log.txt\n";
        return 1;
    }
    thread child([&] {
        lock_guard<mutex> lock(m);
        file << "[Child Data]\n";
    });

    child.join();
    {
        lock_guard<mutex> lock(m);
        file << "[Parent Data]\n";
    }
    file.close();
    cout << "Wrote both lines to log.txt. Threads share the stream object; this is not descriptor inheritance.\n";
}
