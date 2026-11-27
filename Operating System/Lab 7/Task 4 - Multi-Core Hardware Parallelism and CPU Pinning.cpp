#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 4: Multi-Core Hardware Parallelism & CPU Pinning (C++17)
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>
#include <vector>

using namespace std;

namespace {

struct CoreWorkerArg {
    int target_core;
    int actual_core;
    int duration_secs;
    unsigned long long iterations;
    double checksum;
};

void* compute_heavy_work(void* arg) {
    auto* w = static_cast<CoreWorkerArg*>(arg);
    w->actual_core = sched_getcpu();

    unsigned int seed = static_cast<unsigned int>(w->target_core + 1) * 2654435761U;
    double acc = 0.0;
    unsigned long long iters = 0;

    auto start = chrono::steady_clock::now();
    while (true) {
        for (int batch = 0; batch < 10000; ++batch) {
            double r1 = static_cast<double>(rand_r(&seed) % 10000 + 1);
            double r2 = static_cast<double>(rand_r(&seed) % 10000 + 1);
            acc += sqrt(r1) * sin(r2);
            ++iters;
        }
        if (w->duration_secs > 0) {
            double secs = chrono::duration<double>(chrono::steady_clock::now() - start).count();
            if (secs >= static_cast<double>(w->duration_secs)) break;
        }
    }

    w->actual_core = sched_getcpu();
    w->iterations = iters;
    w->checksum = acc;
    return nullptr;
}

} // namespace

int main(int argc, char* argv[]) {
    int duration_secs = 2;
    if (argc > 1) {
        if (strcmp(argv[1], "--forever") == 0) {
            duration_secs = 0;
        } else {
            int v = atoi(argv[1]);
            if (v >= 0) duration_secs = v;
        }
    }

    long num_cores = sysconf(_SC_NPROCESSORS_ONLN);
    if (num_cores < 1) num_cores = 1;

    cout << "=== Lab 7 Task 4: Multi-Core Hardware Parallelism & CPU Pinning ===\n";
    cout << "Online CPU cores: " << num_cores
         << " | Duration: " << (duration_secs == 0 ? "infinite" : to_string(duration_secs) + "s") << "\n\n";

    vector<pthread_t> threads(static_cast<size_t>(num_cores));
    vector<CoreWorkerArg> args(static_cast<size_t>(num_cores));

    for (long i = 0; i < num_cores; ++i) {
        args[static_cast<size_t>(i)] = {static_cast<int>(i), -1, duration_secs, 0, 0.0};
        pthread_create(&threads[static_cast<size_t>(i)], nullptr, compute_heavy_work,
                       &args[static_cast<size_t>(i)]);

        cpu_set_t cpu_set;
        CPU_ZERO(&cpu_set);
        CPU_SET(static_cast<int>(i), &cpu_set);
        pthread_setaffinity_np(threads[static_cast<size_t>(i)], sizeof(cpu_set_t), &cpu_set);
    }

    bool all_pinned = true;
    for (long i = 0; i < num_cores; ++i) {
        pthread_join(threads[static_cast<size_t>(i)], nullptr);
        const auto& a = args[static_cast<size_t>(i)];
        bool matched = (a.actual_core == a.target_core);
        all_pinned = all_pinned && matched;
        cout << "Thread " << i << " pinned to CPU " << a.target_core
             << " | sched_getcpu()=" << a.actual_core
             << " | iterations=" << a.iterations << "\n";
    }

    cout << "\nAffinity Verification: " << (all_pinned ? "PASS" : "FAIL") << "\n";
    return 0;
}
