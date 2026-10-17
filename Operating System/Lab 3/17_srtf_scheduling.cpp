#include <iostream>
#include <vector>
#include <string>
using namespace std;
struct Process { string id; int arrival, burst, remaining, completion = 0; };

int main() {
    vector<Process> jobs = {{"P1", 0, 6, 6}, {"P2", 1, 4, 4}, {"P3", 10, 2, 2}};
    vector<int> timeline;
    int time = 0, completed = 0;
    while (completed < static_cast<int>(jobs.size())) {
        int selected = -1;
        for (int i = 0; i < static_cast<int>(jobs.size()); ++i)
            if (jobs[i].arrival <= time && jobs[i].remaining > 0 &&
                (selected == -1 || jobs[i].remaining < jobs[selected].remaining)) selected = i;
        if (selected == -1) { timeline.push_back(-1); ++time; continue; }
        timeline.push_back(selected);
        --jobs[selected].remaining;
        ++time;
        if (jobs[selected].remaining == 0) {
            jobs[selected].completion = time;
            ++completed;
        }
    }
    cout << "Timeline: ";
    int start = 0;
    for (int i = 1; i <= static_cast<int>(timeline.size()); ++i) {
        if (i == static_cast<int>(timeline.size()) || timeline[i] != timeline[start]) {
            if (timeline[start] >= 0)
                cout << '[' << jobs[timeline[start]].id << ": " << start << '-' << i << "] ";
            start = i;
        }
    }
    cout << "\nPID | Completion | Waiting Time\n";
    for (const auto& job : jobs)
        cout << job.id << " | " << job.completion << " | "
             << job.completion - job.arrival - job.burst << '\n';
    return 0;
}
