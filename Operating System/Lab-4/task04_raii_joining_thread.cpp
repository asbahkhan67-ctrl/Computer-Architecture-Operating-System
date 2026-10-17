#include <iostream>
#include <thread>
#include <utility>

using namespace std;

class JoiningThread {
public:
    explicit JoiningThread(thread worker) : worker_(move(worker)) {}

    JoiningThread(const JoiningThread&) = delete;
    JoiningThread& operator=(const JoiningThread&) = delete;

    ~JoiningThread() {
        if (worker_.joinable()) {
            worker_.join();
        }
    }

private:
    thread worker_;
};

void workerRoutine() {
    cout << "RAII-managed worker is running.\n";
}

int main() {
    {
        JoiningThread worker{thread(workerRoutine)};
        cout << "Leaving scope; the wrapper joins its thread automatically.\n";
    }
    cout << "Worker has been joined.\n";
    return 0;
}
