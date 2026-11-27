#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 13: Strong Scaling Experiment (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

struct SumArgs {
    const long* data;
    std::size_t n;
    int tid;
    int T;
    long long partial;
};

void* sum_worker(void* arg) {
    auto* a = static_cast<SumArgs*>(arg);
    const std::size_t chunk = (a->n + static_cast<std::size_t>(a->T) - 1) /
                              static_cast<std::size_t>(a->T);
    const std::size_t lo = static_cast<std::size_t>(a->tid) * chunk;
    const std::size_t hi = std::min(a->n, lo + chunk);
    long long s = 0;
    for (std::size_t i = lo; i < hi; ++i) {
        s += a->data[i];
    }
    a->partial = s;
    return nullptr;
}

void* noop_worker(void*) {
    return nullptr;
}

double elapsed_ms(std::chrono::steady_clock::time_point a,
                  std::chrono::steady_clock::time_point b) {
    return std::chrono::duration<double, std::milli>(b - a).count();
}

double probe_thread_overhead_ms(int T, int repeats) {
    std::vector<pthread_t> threads(static_cast<std::size_t>(T));
    auto t0 = std::chrono::steady_clock::now();
    for (int r = 0; r < repeats; ++r) {
        for (int t = 0; t < T; ++t) {
            pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, noop_worker, nullptr);
        }
        for (int t = 0; t < T; ++t) {
            pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        }
    }
    auto t1 = std::chrono::steady_clock::now();
    return elapsed_ms(t0, t1) / static_cast<double>(repeats);
}

} // namespace

int main() {
    const std::size_t n = 50000000ULL;
    std::cout << "=== Lab 6 Task 13: Strong Scaling Experiment (T = 1..8) ===\n";
    std::cout << "Fixed problem size n = " << n << " longs\n\n";

    std::vector<long> A(n);
    long long expected = 0;
    for (std::size_t i = 0; i < n; ++i) {
        A[i] = static_cast<long>((i % 50) + 1);
        expected += A[i];
    }

    double T1 = 0.0;
    bool all_ok = true;

    std::cout << std::fixed << std::setprecision(3);
    std::cout << std::left << std::setw(4) << "T"
              << std::setw(12) << "t_T (ms)"
              << std::setw(11) << "S(T)"
              << std::setw(11) << "E(T)"
              << std::setw(14) << "Overhead(ms)"
              << std::setw(8) << "Check"
              << "Speedup vs Ideal (M=meas, I=ideal)\n";
    std::cout << std::string(96, '-') << "\n";

    for (int T = 1; T <= 8; ++T) {
        std::vector<pthread_t> threads(static_cast<std::size_t>(T));
        std::vector<SumArgs> args(static_cast<std::size_t>(T));

        auto t0 = std::chrono::steady_clock::now();
        for (int t = 0; t < T; ++t) {
            args[static_cast<std::size_t>(t)] = {A.data(), n, t, T, 0};
            pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, sum_worker,
                           &args[static_cast<std::size_t>(t)]);
        }
        long long total = 0;
        for (int t = 0; t < T; ++t) {
            pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
            total += args[static_cast<std::size_t>(t)].partial;
        }
        auto t1 = std::chrono::steady_clock::now();

        double t_T = elapsed_ms(t0, t1);
        if (T == 1) T1 = t_T;
        double S = T1 / t_T;
        double E = S / static_cast<double>(T);
        double ovh = probe_thread_overhead_ms(T, 20);
        bool ok = (total == expected);
        all_ok = all_ok && ok;

        int m_col = std::min(32, std::max(0, static_cast<int>(std::round(S * 4.0))));
        int i_col = std::min(32, T * 4);
        std::string bar(34, ' ');
        bar[static_cast<std::size_t>(i_col)] = 'I';
        bar[static_cast<std::size_t>(m_col)] = (m_col == i_col) ? '@' : 'M';

        std::cout << std::left << std::setw(4) << T
                  << std::setw(12) << t_T
                  << std::setw(11) << S
                  << std::setw(11) << E
                  << std::setw(14) << ovh
                  << std::setw(8) << (ok ? "PASS" : "FAIL")
                  << "|" << bar << "|\n";
    }

    std::cout << "\nOverall correctness: " << (all_ok ? "PASS" : "FAIL") << "\n";
    std::cout << "\nConclusion:\n"
              << "Under strong scaling with a fixed 50M-element array, speedup S(T) climbs at "
              << "low thread counts but falls progressively below the ideal line S(T) = T, reducing "
              << "parallel efficiency E(T). Two factors explain this deviation: thread creation/join "
              << "overhead grows linearly with T, and memory-bus bandwidth limits how fast additional "
              << "cores can stream array elements into cache.\n";
    return 0;
}
