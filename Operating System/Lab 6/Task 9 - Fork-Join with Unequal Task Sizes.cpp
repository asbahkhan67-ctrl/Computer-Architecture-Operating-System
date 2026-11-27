#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 9: Fork-Join with Unequal Task Sizes (C++17)
#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

struct BusyArgs {
    int target_ms;
    double actual_ms;
    int tid;
};

void* busy_worker(void* arg) {
    auto* a = static_cast<BusyArgs*>(arg);
    auto start = std::chrono::steady_clock::now();
    volatile unsigned long sink = 0;
    while (true) {
        for (int k = 0; k < 1000; ++k) {
            sink = sink + static_cast<unsigned long>(k);
        }
        auto now = std::chrono::steady_clock::now();
        double ms = std::chrono::duration<double, std::milli>(now - start).count();
        if (ms >= static_cast<double>(a->target_ms)) {
            a->actual_ms = ms;
            break;
        }
    }
    return nullptr;
}

double run_fork_join(const std::vector<int>& work, std::vector<double>& per_thread_ms) {
    const std::size_t T = work.size();
    std::vector<pthread_t> threads(T);
    std::vector<BusyArgs> args(T);

    auto t0 = std::chrono::steady_clock::now();
    for (std::size_t t = 0; t < T; ++t) {
        args[t] = {work[t], 0.0, static_cast<int>(t)};
        pthread_create(&threads[t], nullptr, busy_worker, &args[t]);
    }
    for (std::size_t t = 0; t < T; ++t) {
        pthread_join(threads[t], nullptr);
        per_thread_ms[t] = args[t].actual_ms;
    }
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 9: Fork-Join with Unequal Task Sizes ===\n\n";

    std::vector<int> imbalanced = {100, 400, 100, 400};
    std::vector<int> balanced = {250, 250, 250, 250};
    std::vector<double> d_imbal(4), d_bal(4);

    double t_imbal = run_fork_join(imbalanced, d_imbal);
    double t_bal = run_fork_join(balanced, d_bal);

    bool ok = (t_imbal >= 380.0) && (t_bal >= 230.0) && (t_bal < t_imbal);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << std::left << std::setw(18) << "Schedule"
              << std::setw(32) << "Thread Durations (ms)"
              << std::setw(14) << "Wall (ms)"
              << "Expected\n";
    std::cout << std::string(76, '-') << "\n";

    std::cout << std::left << std::setw(18) << "Imbalanced"
              << d_imbal[0] << ", " << d_imbal[1] << ", " << d_imbal[2] << ", " << d_imbal[3]
              << "  " << std::setw(14) << t_imbal << "~400 ms\n";
    std::cout << std::left << std::setw(18) << "Rebalanced"
              << d_bal[0] << ", " << d_bal[1] << ", " << d_bal[2] << ", " << d_bal[3]
              << "  " << std::setw(14) << t_bal << "~250 ms\n";

    std::cout << "\nSpeedup from rebalancing: " << (t_imbal / t_bal)
              << "x | Check: " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "In a fork-join barrier, total wall time equals the slowest worker: threads 0 and 2 "
              << "finish in 100 ms and sit idle while threads 1 and 3 complete their 400 ms work. "
              << "Redistributing the exact same 1000 ms of total work evenly into {250, 250, 250, 250} "
              << "cuts wall-clock execution from ~400 ms to ~250 ms (a ~1.6x improvement) without "
              << "adding more cores.\n";
    return 0;
}
