#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 1: Sequential vs. Parallel Array Sum (C++17)
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <omp.h>
#include <pthread.h>
#include <vector>

namespace {

struct WorkerArgs {
    const std::vector<long>* arr;
    std::vector<long long>* partials;
    std::size_t n;
    int tid;
    int num_threads;
};

void* sum_worker(void* arg) {
    auto* w = static_cast<WorkerArgs*>(arg);
    const std::size_t chunk = (w->n + static_cast<std::size_t>(w->num_threads) - 1) /
                              static_cast<std::size_t>(w->num_threads);
    const std::size_t lo = static_cast<std::size_t>(w->tid) * chunk;
    const std::size_t hi = std::min(w->n, lo + chunk);
    const long* data = w->arr->data();

    long long local_sum = 0;
    for (std::size_t i = lo; i < hi; ++i) {
        local_sum += data[i];
    }
    (*w->partials)[static_cast<std::size_t>(w->tid)] = local_sum;
    return nullptr;
}

double elapsed_ms(std::chrono::steady_clock::time_point start,
                  std::chrono::steady_clock::time_point end) {
    return std::chrono::duration<double, std::milli>(end - start).count();
}

long long sequential_sum(const std::vector<long>& arr) {
    long long s = 0;
    const std::size_t n = arr.size();
    const long* data = arr.data();
    for (std::size_t i = 0; i < n; ++i) {
        s += data[i];
    }
    return s;
}

long long pthread_sum(const std::vector<long>& arr, int T) {
    std::vector<pthread_t> threads(static_cast<std::size_t>(T));
    std::vector<WorkerArgs> args(static_cast<std::size_t>(T));
    std::vector<long long> partials(static_cast<std::size_t>(T), 0);

    for (int t = 0; t < T; ++t) {
        args[static_cast<std::size_t>(t)] = {&arr, &partials, arr.size(), t, T};
        pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, sum_worker,
                       &args[static_cast<std::size_t>(t)]);
    }
    for (int t = 0; t < T; ++t) {
        pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
    }

    long long total = 0;
    for (long long p : partials) {
        total += p;
    }
    return total;
}

long long openmp_sum(const std::vector<long>& arr, int T) {
    long long total = 0;
    const std::size_t n = arr.size();
    const long* data = arr.data();
    omp_set_num_threads(T);
#pragma omp parallel for reduction(+ : total) schedule(static)
    for (std::size_t i = 0; i < n; ++i) {
        total += data[i];
    }
    return total;
}

} // namespace

int main(int argc, char* argv[]) {
    std::size_t n = 50000000ULL;
    if (argc > 1) {
        long parsed = std::atol(argv[1]);
        if (parsed > 0) n = static_cast<std::size_t>(parsed);
    }

    std::cout << "=== Lab 6 Task 1: Sequential vs. Parallel Array Sum ===\n";
    std::cout << "Array size: " << n << " longs ("
              << (n * sizeof(long)) / (1024.0 * 1024.0) << " MiB)\n";

    std::vector<long> arr(n);
    for (std::size_t i = 0; i < n; ++i) {
        arr[i] = static_cast<long>((i % 100) + 1);
    }

    auto t0 = std::chrono::steady_clock::now();
    volatile long long seq_sink = sequential_sum(arr);
    auto t1 = std::chrono::steady_clock::now();
    long long seq_res = seq_sink;
    double seq_ms = elapsed_ms(t0, t1);

    std::cout << "\nSequential sum = " << seq_res << " | Time = "
              << std::fixed << std::setprecision(2) << seq_ms << " ms\n\n";

    std::cout << std::left << std::setw(6) << "T"
              << std::setw(16) << "Pthread (ms)"
              << std::setw(14) << "Pth Speedup"
              << std::setw(16) << "OpenMP (ms)"
              << std::setw(14) << "OMP Speedup"
              << "Correctness\n";
    std::cout << std::string(78, '-') << "\n";

    const int thread_counts[] = {1, 2, 4, 8};
    for (int T : thread_counts) {
        auto p0 = std::chrono::steady_clock::now();
        long long p_res = pthread_sum(arr, T);
        auto p1 = std::chrono::steady_clock::now();
        double p_ms = elapsed_ms(p0, p1);

        auto o0 = std::chrono::steady_clock::now();
        long long o_res = openmp_sum(arr, T);
        auto o1 = std::chrono::steady_clock::now();
        double o_ms = elapsed_ms(o0, o1);

        bool ok = (p_res == seq_res) && (o_res == seq_res);
        std::cout << std::left << std::setw(6) << T
                  << std::setw(16) << p_ms
                  << std::setw(14) << (seq_ms / p_ms)
                  << std::setw(16) << o_ms
                  << std::setw(14) << (seq_ms / o_ms)
                  << (ok ? "PASS" : "FAIL") << "\n";
    }

    std::cout << "\nConclusion:\n"
              << "Both pthreads (chunked into local accumulators) and OpenMP reduction(+:sum) "
              << "match the sequential result exactly. Speedup improves from T=1 to T=4 as "
              << "independent contiguous chunks execute across hardware cores. Beyond 4-8 "
              << "threads, gains flatten because array summation is memory-bandwidth bound "
              << "rather than compute bound. Keeping local_sum in a register avoids false "
              << "sharing on the shared partial-sums array.\n";
    return 0;
}
