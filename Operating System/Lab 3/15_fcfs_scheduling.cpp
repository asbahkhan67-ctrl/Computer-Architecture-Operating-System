#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <iomanip>
using namespace std;
struct Process { string id; int arrival, burst, completion = 0; };

int main() {
    vector<Process> jobs = {{"P1", 0, 5}, {"P2", 1, 3}, {"P3", 2, 8}};
    sort(jobs.begin(), jobs.end(), [](const auto& a, const auto& b) {
        return a.arrival < b.arrival;
    });
    int time = 0, totalWait = 0;
    cout << "PID | Arrival | Burst | Completion | Turnaround | Wait\n";
    for (auto& job : jobs) {
        time = max(time, job.arrival);
        job.completion = time + job.burst;
        int turnaround = job.completion - job.arrival;
        int waiting = turnaround - job.burst;
        time = job.completion;
        totalWait += waiting;
        cout << job.id << " | " << job.arrival << " | " << job.burst << " | "
             << job.completion << " | " << turnaround << " | " << waiting << '\n';
    }
    cout << fixed << setprecision(2) << "Average Waiting Time: "
         << static_cast<double>(totalWait) / jobs.size() << " ms\n";
    return 0;
}
