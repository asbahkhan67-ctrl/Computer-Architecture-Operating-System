#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 14: Amdahl vs. Gustafson on the Same Data (C++17)
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
    for (std::size_t i = lo; i < hi; ++i) s += a->data[i];
    a->partial = s;
    return nullptr;
}

double run_sum_ms(const std::vector<long>& A, int T, long long& out_sum) {
    std::vector<pthread_t> threads(static_cast<std::size_t>(T));
    std::vector<SumArgs> args(static_cast<std::size_t>(T));
    auto t0 = std::chrono::steady_clock::now();
    for (int t = 0; t < T; ++t) {
        args[static_cast<std::size_t>(t)] = {A.data(), A.size(), t, T, 0};
        pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, sum_worker,
                       &args[static_cast<std::size_t>(t)]);
    }
    long long total = 0;
    for (int t = 0; t < T; ++t) {
        pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        total += args[static_cast<std::size_t>(t)].partial;
    }
    auto t1 = std::chrono::steady_clock::now();
    out_sum = total;
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

} // namespace

int main() {
    const std::size_t n = 50000000ULL;
    std::cout << "=== Lab 6 Task 14: Amdahl vs. Gustafson on the Same Data ===\n\n";

    std::vector<long> A(n);
    long long expected = 0;
    for (std::size_t i = 0; i < n; ++i) {
        A[i] = static_cast<long>((i % 50) + 1);
        expected += A[i];
    }

    std::vector<double> meas_S(9, 1.0);
    double T1 = 0.0;
    bool all_ok = true;
    for (int N = 1; N <= 8; ++N) {
        long long s = 0;
        double t = run_sum_ms(A, N, s);
        if (N == 1) T1 = t;
        meas_S[static_cast<std::size_t>(N)] = T1 / t;
        all_ok = all_ok && (s == expected);
    }

    // Estimate average serial fraction f across N=2..8 using Task 15 formula, clamped to [0, 1]
    double f_sum = 0.0;
    int f_cnt = 0;
    for (int N = 2; N <= 8; ++N) {
        double sm = meas_S[static_cast<std::size_t>(N)];
        double f_est = (1.0 / sm - 1.0 / N) / (1.0 - 1.0 / N);
        f_est = std::clamp(f_est, 0.0, 1.0);
        f_sum += f_est;
        ++f_cnt;
    }
    double f_avg = f_sum / static_cast<double>(f_cnt);
    double p_est = 1.0 - f_avg;

    std::cout << std::fixed << std::setprecision(4);
    std::cout << "Estimated serial fraction f = " << f_avg
              << ", parallel fraction p = " << p_est
              << " | Correctness: " << (all_ok ? "PASS" : "FAIL") << "\n\n";

    std::cout << std::left << std::setw(5) << "N"
              << std::setw(14) << "S_Amdahl(N)"
              << std::setw(16) << "S_Gustafson(N)"
              << std::setw(14) << "Measured S(N)"
              << "Plot (A=Amdahl, G=Gustafson, M=Meas)\n";
    std::cout << std::string(86, '-') << "\n";

    for (int N = 1; N <= 8; ++N) {
        double s_amd = 1.0 / ((1.0 - p_est) + p_est / static_cast<double>(N));
        double s_gus = static_cast<double>(N) - (1.0 - p_est) * static_cast<double>(N - 1);
        double s_mea = meas_S[static_cast<std::size_t>(N)];

        std::string bar(34, ' ');
        auto col = [](double v) {
            return static_cast<std::size_t>(std::min(32, std::max(0, static_cast<int>(std::round(v * 4.0)))));
        };
        bar[col(s_amd)] = 'A';
        bar[col(s_gus)] = 'G';
        bar[col(s_mea)] = 'M';

        std::cout << std::left << std::setw(5) << N
                  << std::setprecision(3)
                  << std::setw(14) << s_amd
                  << std::setw(16) << s_gus
                  << std::setw(14) << s_mea
                  << "|" << bar << "|\n";
    }

    std::cout << "\nWhy Amdahl and Gustafson answer different questions:\n"
              << "Amdahl's Law assumes a fixed total problem size (strong scaling) and asks how much "
              << "faster that single problem finishes on N cores, so the unparallelizable serial fraction "
              << "(1 - p) creates a hard ceiling of 1/(1 - p). Gustafson's Law instead assumes fixed "
              << "wall-clock execution time (weak scaling) and asks how much larger a problem N cores can "
              << "solve in the same time, scaling the parallel work proportionally to N while keeping "
              << "serial overhead constant so scaled speedup grows linearly as N - (1 - p)(N - 1).\n";
    return 0;
}
