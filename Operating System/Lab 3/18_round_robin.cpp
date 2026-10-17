#include <iostream>
#include <string>
#include <vector>
#include <queue>
using namespace std;
struct Process { string id; int arrival, burst, remaining, completion = 0; };

int main() {
    vector<Process> jobs = {{"P1", 0, 3, 3}, {"P2", 0, 2, 2}, {"P3", 0, 4, 4}};
    queue<int> ready;
    for (int i = 0; i < static_cast<int>(jobs.size()); ++i) ready.push(i);
    int time = 0, quantum = 2;
    while (!ready.empty()) {
        int i = ready.front(); ready.pop();
        int runTime = min(quantum, jobs[i].remaining);
        time += runTime;
        jobs[i].remaining -= runTime;
        if (jobs[i].remaining > 0) ready.push(i);
        else jobs[i].completion = time;
    }
    cout << "Quantum = 2\nExecution: P1 (2 ms) -> P2 (2 ms) -> P3 (2 ms) -> P1 (1 ms) -> P3 (2 ms)\n";
    cout << "PID | Turnaround | Wait\n";
    for (const auto& job : jobs)
        cout << job.id << " | " << job.completion - job.arrival << " | "
             << job.completion - job.arrival - job.burst << '\n';
    return 0;
}
