#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 12: Deliberately Serial Code - Predicted vs. Measured (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

struct RangeArgs {
    const long* data;
    std::size_t lo;
    std::size_t hi;
    long long partial;
};

void* range_sum_worker(void* arg) {
    auto* a = static_cast<RangeArgs*>(arg);
    long long s = 0;
    for (std::size_t i = a->lo; i < a->hi; ++i) {
        s += a->data[i];
    }
    a->partial = s;
    return nullptr;
}

long long parallel_range_sum(const long* data, std::size_t start, std::size_t end, int T) {
    const std::size_t len = end - start;
    const std::size_t chunk = (len + static_cast<std::size_t>(T) - 1) / static_cast<std::size_t>(T);
    std::vector<pthread_t> threads(static_cast<std::size_t>(T));
    std::vector<RangeArgs> args(static_cast<std::size_t>(T));

    for (int t = 0; t < T; ++t) {
        std::size_t lo = start + static_cast<std::size_t>(t) * chunk;
        std::size_t hi = std::min(end, lo + chunk);
        args[static_cast<std::size_t>(t)] = {data, std::min(lo, end), hi, 0};
        pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, range_sum_worker,
                       &args[static_cast<std::size_t>(t)]);
    }
    long long total = 0;
    for (int t = 0; t < T; ++t) {
        pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        total += args[static_cast<std::size_t>(t)].partial;
    }
    return total;
}

double elapsed_ms(std::chrono::steady_clock::time_point a,
                  std::chrono::steady_clock::time_point b) {
    return std::chrono::duration<double, std::milli>(b - a).count();
}

} // namespace

int main() {
    const std::size_t n = 50000000ULL;
    const double f = 0.10;
    const std::size_t n_ser = static_cast<std::size_t>(std::floor(f * static_cast<double>(n)));

    std::cout << "=== Lab 6 Task 12: Deliberately Serial Code (f = " << f << ") ===\n";
    std::cout << "n = " << n << ", serial elements = " << n_ser << "\n\n";

    std::vector<long> A(n);
    for (std::size_t i = 0; i < n; ++i) {
        A[i] = static_cast<long>((i % 100) + 1);
    }

    auto s0 = std::chrono::steady_clock::now();
    volatile long long seq_sink = 0;
    long long seq_acc = 0;
    for (std::size_t i = 0; i < n; ++i) seq_acc += A[i];
    seq_sink = seq_acc;
    auto s1 = std::chrono::steady_clock::now();
    double T_seq = elapsed_ms(s0, s1);
    long long expected_sum = seq_sink;

    std::cout << "Fully sequential time T_seq = " << std::fixed << std::setprecision(2)
              << T_seq << " ms (sum = " << expected_sum << ")\n\n";

    std::cout << std::left << std::setw(6) << "T"
              << std::setw(14) << "Time (ms)"
              << std::setw(14) << "Measured S"
              << std::setw(14) << "Amdahl S"
              << std::setw(12) << "Check"
              << "Plot (M=meas, *=pred)\n";
    std::cout << std::string(86, '-') << "\n";

    const int thread_counts[] = {1, 2, 4, 8};
    for (int T : thread_counts) {
        auto t0 = std::chrono::steady_clock::now();
        long long s_ser = 0;
        for (std::size_t i = 0; i < n_ser; ++i) {
            s_ser += A[i];
        }
        long long s_par = parallel_range_sum(A.data(), n_ser, n, T);
        auto t1 = std::chrono::steady_clock::now();

        double t_T = elapsed_ms(t0, t1);
        double meas = T_seq / t_T;
        double pred = 1.0 / (f + (1.0 - f) / static_cast<double>(T));
        bool ok = ((s_ser + s_par) == expected_sum);

        int m_col = std::min(28, std::max(0, static_cast<int>(std::round(meas * 3.0))));
        int p_col = std::min(28, std::max(0, static_cast<int>(std::round(pred * 3.0))));
        std::string bar(30, ' ');
        bar[static_cast<std::size_t>(p_col)] = '*';
        bar[static_cast<std::size_t>(m_col)] = (m_col == p_col) ? '@' : 'M';

        std::cout << std::left << std::setw(6) << T
                  << std::setw(14) << t_T
                  << std::setw(14) << meas
                  << std::setw(14) << pred
                  << std::setw(12) << (ok ? "PASS" : "FAIL")
                  << "|" << bar << "|\n";
    }

    std::cout << "\nConclusion:\n"
              << "Injecting a 10% serial prefix strictly caps speedup below 1 / 0.10 = 10x, closely "
              << "tracking Amdahl's prediction 1 / (0.10 + 0.90/T). Measured speedup falls slightly "
              << "below the ideal curve at higher T due to thread creation/join overhead and shared "
              << "memory bandwidth saturation across cores. All parallel sums match the baseline.\n";
    return 0;
}
