#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 4: Parallel Maximum with Reduction (C++17)
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <limits>
#include <pthread.h>
#include <vector>

namespace {

struct MaxArgs {
    const std::vector<long>* arr;
    std::vector<long>* lmax;
    std::size_t n;
    int tid;
    int num_threads;
};

void* local_max_worker(void* arg) {
    auto* w = static_cast<MaxArgs*>(arg);
    const std::size_t chunk = (w->n + static_cast<std::size_t>(w->num_threads) - 1) /
                              static_cast<std::size_t>(w->num_threads);
    const std::size_t lo = static_cast<std::size_t>(w->tid) * chunk;
    const std::size_t hi = std::min(w->n, lo + chunk);

    long m = std::numeric_limits<long>::min();
    const long* data = w->arr->data();
    if (lo < hi) {
        m = data[lo];
        for (std::size_t i = lo + 1; i < hi; ++i) {
            if (data[i] > m) {
                m = data[i];
            }
        }
    }
    // Single write to private slot after local scan: zero shared writes during parallel phase
    (*w->lmax)[static_cast<std::size_t>(w->tid)] = m;
    return nullptr;
}

double elapsed_ms(std::chrono::steady_clock::time_point start,
                  std::chrono::steady_clock::time_point end) {
    return std::chrono::duration<double, std::milli>(end - start).count();
}

} // namespace

int main() {
    const std::size_t n = 50000000ULL;
    std::cout << "=== Lab 6 Task 4: Parallel Maximum with Reduction ===\n";
    std::cout << "Elements: " << n << "\n\n";

    std::vector<long> A(n);
    std::uint64_t rng = 0x9e3779b97f4a7c15ULL;
    for (std::size_t i = 0; i < n; ++i) {
        rng ^= rng >> 12;
        rng ^= rng << 25;
        rng ^= rng >> 27;
        A[i] = static_cast<long>((rng * 0x2545F4914F6CDD1DULL) % 1000000000ULL);
    }
    A[n * 7 / 11] = 1987654321L; // Guaranteed known global max

    // (a) Single-thread baseline
    auto s0 = std::chrono::steady_clock::now();
    long seq_max = A[0];
    for (std::size_t i = 1; i < n; ++i) {
        if (A[i] > seq_max) seq_max = A[i];
    }
    auto s1 = std::chrono::steady_clock::now();
    double t_seq = elapsed_ms(s0, s1);

    std::cout << "Single-thread max = " << seq_max << " | Time = "
              << std::fixed << std::setprecision(2) << t_seq << " ms\n\n";

    std::cout << std::left << std::setw(8) << "T"
              << std::setw(14) << "Time (ms)"
              << std::setw(12) << "Speedup"
              << std::setw(16) << "Reduced Max"
              << "Correctness\n";
    std::cout << std::string(62, '-') << "\n";

    const int thread_counts[] = {1, 2, 4, 8};
    for (int T : thread_counts) {
        std::vector<pthread_t> threads(static_cast<std::size_t>(T));
        std::vector<MaxArgs> args(static_cast<std::size_t>(T));
        std::vector<long> lmax(static_cast<std::size_t>(T), std::numeric_limits<long>::min());

        auto p0 = std::chrono::steady_clock::now();
        for (int t = 0; t < T; ++t) {
            args[static_cast<std::size_t>(t)] = {&A, &lmax, n, t, T};
            pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, local_max_worker,
                           &args[static_cast<std::size_t>(t)]);
        }
        for (int t = 0; t < T; ++t) {
            pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        }
        // Sequential reduction strictly after join
        long M = lmax[0];
        for (int t = 1; t < T; ++t) {
            if (lmax[static_cast<std::size_t>(t)] > M) {
                M = lmax[static_cast<std::size_t>(t)];
            }
        }
        auto p1 = std::chrono::steady_clock::now();
        double t_par = elapsed_ms(p0, p1);

        std::cout << std::left << std::setw(8) << T
                  << std::setw(14) << t_par
                  << std::setw(12) << (t_seq / t_par)
                  << std::setw(16) << M
                  << (M == seq_max ? "PASS" : "FAIL") << "\n";
    }

    std::cout << "\nConclusion:\n"
              << "Every worker scans its disjoint chunk into a register variable and writes once "
              << "to its private slot lmax[t], avoiding any shared writes or mutex contention. "
              << "After pthread_join guarantees memory visibility, the main thread performs an "
              << "O(T) sequential reduction over lmax[0..T-1] and recovers the exact maximum. "
              << "Like array sum, parallel max is memory-bandwidth bound at larger thread counts.\n";
    return 0;
}
