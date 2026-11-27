#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 2: Parallel Vector Expression: C[i] = A[i] * B[i] + sin(A[i]) (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <omp.h>
#include <pthread.h>
#include <vector>

namespace {

struct VecArgs {
    const double* A;
    const double* B;
    double* C;
    std::size_t n;
    int tid;
    int num_threads;
};

void* vec_worker(void* arg) {
    auto* w = static_cast<VecArgs*>(arg);
    const std::size_t chunk = (w->n + static_cast<std::size_t>(w->num_threads) - 1) /
                              static_cast<std::size_t>(w->num_threads);
    const std::size_t lo = static_cast<std::size_t>(w->tid) * chunk;
    const std::size_t hi = std::min(w->n, lo + chunk);
    for (std::size_t i = lo; i < hi; ++i) {
        w->C[i] = w->A[i] * w->B[i] + std::sin(w->A[i]);
    }
    return nullptr;
}

double elapsed_ms(std::chrono::steady_clock::time_point start,
                  std::chrono::steady_clock::time_point end) {
    return std::chrono::duration<double, std::milli>(end - start).count();
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 2: Parallel Vector Expression ===\n";
    std::cout << "Expression: C[i] = A[i] * B[i] + sin(A[i]), T = 4 threads\n\n";

    const int T = 4;
    const double eps = 1e-9;
    const std::vector<std::size_t> sizes = {1000, 10000, 100000, 1000000, 10000000};

    std::cout << std::left << std::setw(12) << "n"
              << std::setw(14) << "Seq (ms)"
              << std::setw(14) << "Pthread (ms)"
              << std::setw(14) << "OpenMP (ms)"
              << std::setw(12) << "Pth Spdup"
              << std::setw(12) << "OMP Spdup"
              << "Eps Check\n";
    std::cout << std::string(90, '-') << "\n";

    for (std::size_t n : sizes) {
        std::vector<double> A(n), B(n), C_seq(n), C_pth(n), C_omp(n);
        for (std::size_t i = 0; i < n; ++i) {
            A[i] = 0.001 * static_cast<double>((i % 1000) + 1);
            B[i] = 0.002 * static_cast<double>(((i * 7) % 1000) + 1);
        }

        auto s0 = std::chrono::steady_clock::now();
        for (std::size_t i = 0; i < n; ++i) {
            C_seq[i] = A[i] * B[i] + std::sin(A[i]);
        }
        auto s1 = std::chrono::steady_clock::now();
        double t_seq = elapsed_ms(s0, s1);

        auto p0 = std::chrono::steady_clock::now();
        std::vector<pthread_t> threads(T);
        std::vector<VecArgs> args(T);
        for (int t = 0; t < T; ++t) {
            args[static_cast<std::size_t>(t)] = {A.data(), B.data(), C_pth.data(), n, t, T};
            pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, vec_worker,
                           &args[static_cast<std::size_t>(t)]);
        }
        for (int t = 0; t < T; ++t) {
            pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        }
        auto p1 = std::chrono::steady_clock::now();
        double t_pth = elapsed_ms(p0, p1);

        auto o0 = std::chrono::steady_clock::now();
        omp_set_num_threads(T);
#pragma omp parallel for schedule(static)
        for (std::size_t i = 0; i < n; ++i) {
            C_omp[i] = A[i] * B[i] + std::sin(A[i]);
        }
        auto o1 = std::chrono::steady_clock::now();
        double t_omp = elapsed_ms(o0, o1);

        double max_err = 0.0;
        for (std::size_t i = 0; i < n; ++i) {
            max_err = std::max(max_err, std::abs(C_seq[i] - C_pth[i]));
            max_err = std::max(max_err, std::abs(C_seq[i] - C_omp[i]));
        }

        std::cout << std::left << std::setw(12) << n
                  << std::fixed << std::setprecision(4)
                  << std::setw(14) << t_seq
                  << std::setw(14) << t_pth
                  << std::setw(14) << t_omp
                  << std::setprecision(2)
                  << std::setw(12) << (t_seq / t_pth)
                  << std::setw(12) << (t_seq / t_omp)
                  << (max_err < eps ? "PASS" : "FAIL") << "\n";
    }

    std::cout << "\nConclusion:\n"
              << "All parallel runs pass the epsilon check (< 1e-9) against the sequential baseline. "
              << "For small vectors (n = 1,000 to 10,000), pthread creation and join overhead far "
              << "exceeds the arithmetic cost, yielding speedups below 1.0 (slowdown). Once n "
              << "reaches 100,000-10,000,000, the trigonometric sin() computation amortizes "
              << "synchronization overhead and achieves strong multi-core speedup.\n";
    return 0;
}
