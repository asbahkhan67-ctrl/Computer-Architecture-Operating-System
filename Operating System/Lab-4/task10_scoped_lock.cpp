#include <iostream>
#include <mutex>
#include <thread>

using namespace std;

int main() {
    mutex accountAMutex;
    mutex accountBMutex;
    int accountA = 100;
    int accountB = 100;

    auto transfer = [&](int amount) {
        scoped_lock lock(accountAMutex, accountBMutex);
        accountA -= amount;
        accountB += amount;
    };

    thread firstTransfer(transfer, 10);
    thread secondTransfer(transfer, 20);
    firstTransfer.join();
    secondTransfer.join();

    cout << "Account A: " << accountA << '\n';
    cout << "Account B: " << accountB << '\n';
    cout << "Combined balance: " << accountA + accountB << '\n';
    return 0;
}
