#include <iostream>
#include <string>
#include <vector>
using namespace std;
struct Process { string id; int arrival, burst, priority, remaining, completion = 0; };

int main() {
    // A smaller number means a higher priority.
    vector<Process> jobs = {{"P1", 0, 4, 2, 4}, {"P2", 1, 2, 1, 2}, {"P3", 1, 2, 3, 2}};
    int time = 0, completed = 0;
    while (completed < static_cast<int>(jobs.size())) {
        int selected = -1;
        for (int i = 0; i < static_cast<int>(jobs.size()); ++i)
            if (jobs[i].arrival <= time && jobs[i].remaining > 0 &&
                (selected == -1 || jobs[i].priority < jobs[selected].priority)) selected = i;
        if (selected == -1) { ++time; continue; }
        --jobs[selected].remaining;
        ++time;
        if (jobs[selected].remaining == 0) { jobs[selected].completion = time; ++completed; }
    }
    cout << "PID | Priority | Burst | Arrival | Waiting Time\n";
    for (const auto& job : jobs)
        cout << job.id << " | " << job.priority << " | " << job.burst << " | "
             << job.arrival << " | " << job.completion - job.arrival - job.burst << '\n';
    return 0;
}
