#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
using namespace std;
struct Process { string id; int arrival, burst, completion = 0; bool done = false; };

int main() {
    vector<Process> jobs = {{"P1", 0, 6}, {"P2", 1, 8}, {"P3", 2, 2}};
    int time = 0, completed = 0, totalWait = 0;
    while (completed < static_cast<int>(jobs.size())) {
        int selected = -1;
        for (int i = 0; i < static_cast<int>(jobs.size()); ++i)
            if (!jobs[i].done && jobs[i].arrival <= time &&
                (selected == -1 || jobs[i].burst < jobs[selected].burst)) selected = i;
        if (selected == -1) { ++time; continue; }
        Process& job = jobs[selected];
        job.completion = time + job.burst;
        int waiting = time - job.arrival;
        totalWait += waiting;
        time = job.completion;
        job.done = true;
        ++completed;
    }
    cout << "Execution Order: P1 -> P3 -> P2\nPID | Burst | Wait Time | Turnaround Time\n";
    for (const auto& job : jobs)
        cout << job.id << " | " << job.burst << " | "
             << job.completion - job.arrival - job.burst << " | "
             << job.completion - job.arrival << '\n';
    cout << fixed << setprecision(2) << "Average Waiting Time: "
         << static_cast<double>(totalWait) / jobs.size() << " ms\n";
    return 0;
}
