#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 15: Estimate the Serial Fraction from Measurements (C++17)
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
    std::size_t lo;
    std::size_t hi;
    long long partial;
};

void* sum_worker(void* arg) {
    auto* a = static_cast<SumArgs*>(arg);
    long long s = 0;
    for (std::size_t i = a->lo; i < a->hi; ++i) s += a->data[i];
    a->partial = s;
    return nullptr;
}

double timed_parallel_sum(const std::vector<long>& A, std::size_t serial_elems, int T,
                          long long& out_sum) {
    auto t0 = std::chrono::steady_clock::now();
    long long ser = 0;
    for (std::size_t i = 0; i < serial_elems; ++i) ser += A[i];

    const std::size_t rem = A.size() - serial_elems;
    const std::size_t chunk = (rem + static_cast<std::size_t>(T) - 1) / static_cast<std::size_t>(T);
    std::vector<pthread_t> threads(static_cast<std::size_t>(T));
    std::vector<SumArgs> args(static_cast<std::size_t>(T));
    for (int t = 0; t < T; ++t) {
        std::size_t lo = serial_elems + static_cast<std::size_t>(t) * chunk;
        std::size_t hi = std::min(A.size(), lo + chunk);
        args[static_cast<std::size_t>(t)] = {A.data(), std::min(lo, A.size()), hi, 0};
        pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, sum_worker,
                       &args[static_cast<std::size_t>(t)]);
    }
    long long par = 0;
    for (int t = 0; t < T; ++t) {
        pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        par += args[static_cast<std::size_t>(t)].partial;
    }
    auto t1 = std::chrono::steady_clock::now();
    out_sum = ser + par;
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

void run_experiment(const std::string& title, const std::vector<long>& A,
                    long long expected, std::size_t serial_elems) {
    std::cout << "--- " << title << " ---\n";
    long long s1 = 0;
    double T1 = timed_parallel_sum(A, serial_elems, 1, s1);
    bool all_ok = (s1 == expected);

    std::cout << std::fixed << std::setprecision(4);
    std::cout << std::left << std::setw(5) << "N"
              << std::setw(12) << "Time(ms)"
              << std::setw(12) << "S_meas"
              << std::setw(14) << "Implied f"
              << "Speedup Plot\n";
    std::cout << std::string(70, '-') << "\n";

    double f_min = 1e9, f_max = -1e9;
    for (int N = 1; N <= 8; ++N) {
        long long s = 0;
        double tN = (N == 1) ? T1 : timed_parallel_sum(A, serial_elems, N, s);
        if (N > 1) all_ok = all_ok && (s == expected);
        double S = T1 / tN;
        int bars = std::min(24, std::max(1, static_cast<int>(std::round(S * 3.0))));
        if (N == 1) {
            std::cout << std::left << std::setw(5) << N
                      << std::setprecision(2) << std::setw(12) << tN
                      << std::setprecision(3) << std::setw(12) << S
                      << std::setw(14) << "N/A (N=1)"
                      << std::string(static_cast<std::size_t>(bars), '#') << "\n";
        } else {
            double f = (1.0 / S - 1.0 / static_cast<double>(N)) /
                       (1.0 - 1.0 / static_cast<double>(N));
            f_min = std::min(f_min, f);
            f_max = std::max(f_max, f);
            std::cout << std::left << std::setw(5) << N
                      << std::setprecision(2) << std::setw(12) << tN
                      << std::setprecision(4) << std::setw(12) << S
                      << std::setw(14) << f
                      << std::string(static_cast<std::size_t>(bars), '#') << "\n";
        }
    }
    std::cout << "Correctness: " << (all_ok ? "PASS" : "FAIL")
              << " | Spread of implied f: [" << f_min << ", " << f_max
              << "] (delta = " << (f_max - f_min) << ")\n\n";
}

} // namespace

int main() {
    const std::size_t n = 50000000ULL;
    std::cout << "=== Lab 6 Task 15: Estimate Serial Fraction from Measurements ===\n\n";

    std::vector<long> A(n);
    long long expected = 0;
    for (std::size_t i = 0; i < n; ++i) {
        A[i] = static_cast<long>((i % 50) + 1);
        expected += A[i];
    }

    run_experiment("Pure Parallel Sum (serial_elems = 0)", A, expected, 0);
    run_experiment("Forced 15% Serial Prefix (serial_elems = 0.15 * n)", A, expected,
                   static_cast<std::size_t>(0.15 * static_cast<double>(n)));

    std::cout << "Conclusion:\n"
              << "Inverting Amdahl's Law yields f = (1/S_meas - 1/N) / (1 - 1/N). If Amdahl's "
              << "idealized fixed-serial-fraction assumption held perfectly, implied f would stay "
              << "constant across all N. In practice, implied f drifts upward as N increases because "
              << "thread creation overhead and memory-bandwidth contention grow with thread count, "
              << "violating the constant-overhead assumption.\n";
    return 0;
}
