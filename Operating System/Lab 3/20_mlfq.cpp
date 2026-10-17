#include <iostream>
#include <string>
#include <queue>
#include <algorithm>
using namespace std;
struct Process { string id; int remaining; };

int main() {
    queue<Process> q1, q2, q3;
    q1.push({"P1", 8});
    q1.push({"P2", 1});
    int time = 0;
    while (!q1.empty() || !q2.empty() || !q3.empty()) {
        if (!q1.empty()) {
            Process job = q1.front(); q1.pop();
            int slice = min(2, job.remaining);
            cout << "Time " << time << ": " << job.id << " runs " << slice << " ms in Q1";
            time += slice; job.remaining -= slice;
            if (job.remaining > 0) { cout << " -> Demoted to Q2\n"; q2.push(job); }
            else cout << " -> Finished\n";
        } else if (!q2.empty()) {
            Process job = q2.front(); q2.pop();
            int slice = min(4, job.remaining);
            cout << "Time " << time << ": " << job.id << " runs " << slice << " ms in Q2";
            time += slice; job.remaining -= slice;
            if (job.remaining > 0) { cout << " -> Demoted to Q3\n"; q3.push(job); }
            else cout << " -> Finished\n";
            if (time >= 7 && !q3.empty()) {
                cout << "Time " << time << ": aging promotes " << q3.front().id << " from Q3 to Q1\n";
                q1.push(q3.front()); q3.pop();
            }
        } else {
            Process job = q3.front(); q3.pop();
            cout << "Time " << time << ": " << job.id << " runs " << job.remaining << " ms in Q3 -> Finished\n";
            time += job.remaining;
        }
    }
    return 0;
}
