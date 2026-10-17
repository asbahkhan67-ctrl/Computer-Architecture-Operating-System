#include <iostream>
#include <thread>
#include <mutex>

using namespace std;

mutex outputMutex;
void build(int level, int maxDepth, char side = 'R') {
    if (level >= maxDepth) return;
    {
        lock_guard<mutex> lock(outputMutex);
        cout << "Level " << level + 1 << ' ' << side << " child thread " << this_thread::get_id() << '\n';
    }
    thread left(build, level + 1, maxDepth, 'L');
    thread right(build, level + 1, maxDepth, 'R');
    left.join();
    right.join();
}
int main() {
    build(0, 3);
    cout << "Tree routines completed bottom-up.\n";
}
