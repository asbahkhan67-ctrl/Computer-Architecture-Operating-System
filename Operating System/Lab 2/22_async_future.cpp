#include <iostream>
#include <future>
#include <chrono>
#include <thread>
using namespace std;
int main()
{
    auto task = async(launch::async, []
                      {this_thread::sleep_for(chrono::seconds(1));return 3.14159; });
    cout << "Main thread continues work while async task computes...\n";
    cout << "Result received: " << task.get() << "\n";
}
