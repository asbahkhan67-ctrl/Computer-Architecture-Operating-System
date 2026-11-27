#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 5: Dot Product - Demonstrating a Race Condition and Fixes (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <omp.h>
#include <pthread.h>
#include <vector>

namespace {

struct RaceState {
    const double* A;
    const double* B;
    std::size_t n;
    int num_threads;
    volatile double shared_dot;
    double mutex_dot;
    pthread_mutex_t mtx;
};

struct WorkerCtx {
    RaceState* st;
    int tid;
};

// Intentionally racy: accumulates into a shared global inside the loop to expose lost updates
void* racy_worker(void* arg) {
    auto* ctx = static_cast<WorkerCtx*>(arg);
    RaceState* st = ctx->st;
    const std::size_t chunk = (st->n + static_cast<std::size_t>(st->num_threads) - 1) /
                              static_cast<std::size_t>(st->num_threads);
    const std::size_t lo = static_cast<std::size_t>(ctx->tid) * chunk;
    const std::size_t hi = std::min(st->n, lo + chunk);

    for (std::size_t i = lo; i < hi; ++i) {
        st->shared_dot = st->shared_dot + st->A[i] * st->B[i];
    }
    return nullptr;
}

// Fix 1: local partial sum combined once under pthread_mutex_t
void* mutex_worker(void* arg) {
    auto* ctx = static_cast<WorkerCtx*>(arg);
    RaceState* st = ctx->st;
    const std::size_t chunk = (st->n + static_cast<std::size_t>(st->num_threads) - 1) /
                              static_cast<std::size_t>(st->num_threads);
    const std::size_t lo = static_cast<std::size_t>(ctx->tid) * chunk;
    const std::size_t hi = std::min(st->n, lo + chunk);

    double local_p = 0.0;
    for (std::size_t i = lo; i < hi; ++i) {
        local_p += st->A[i] * st->B[i];
    }
    pthread_mutex_lock(&st->mtx);
    st->mutex_dot += local_p;
    pthread_mutex_unlock(&st->mtx);
    return nullptr;
}

double elapsed_ms(std::chrono::steady_clock::time_point start,
                  std::chrono::steady_clock::time_point end) {
    return std::chrono::duration<double, std::milli>(end - start).count();
}

} // namespace

int main() {
    const std::size_t n = 2000000;
    const int T = 8;

    std::cout << "=== Lab 6 Task 5: Dot Product Race Condition & Fixes ===\n";
    std::cout << "Vector length: " << n << ", Threads: " << T << "\n\n";

    std::vector<double> A(n), B(n);
    for (std::size_t i = 0; i < n; ++i) {
        A[i] = 1.0;
        B[i] = 1.0;
    }

    auto s0 = std::chrono::steady_clock::now();
    double seq_dot = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        seq_dot += A[i] * B[i];
    }
    auto s1 = std::chrono::steady_clock::now();
    double t_seq = elapsed_ms(s0, s1);

    RaceState state{A.data(), B.data(), n, T, 0.0, 0.0, PTHREAD_MUTEX_INITIALIZER};
    std::vector<pthread_t> threads(T);
    std::vector<WorkerCtx> ctxs(T);

    std::cout << std::fixed << std::setprecision(1);
    std::cout << "Expected sequential dot product = " << seq_dot << "\n\n";
    std::cout << "--- Buggy Racy Runs (5 repetitions) ---\n";
    double t_racy_last = 0.0;
    for (int run = 1; run <= 5; ++run) {
        state.shared_dot = 0.0;
        auto r0 = std::chrono::steady_clock::now();
        for (int t = 0; t < T; ++t) {
            ctxs[static_cast<std::size_t>(t)] = {&state, t};
            pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, racy_worker,
                           &ctxs[static_cast<std::size_t>(t)]);
        }
        for (int t = 0; t < T; ++t) {
            pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
        }
        auto r1 = std::chrono::steady_clock::now();
        t_racy_last = elapsed_ms(r0, r1);
        double lost = seq_dot - state.shared_dot;
        std::cout << "  Run " << run << ": shared_dot = " << std::setw(10) << state.shared_dot
                  << " | Lost updates = " << lost << "\n";
    }

    // Fix 1: Mutex
    state.mutex_dot = 0.0;
    auto m0 = std::chrono::steady_clock::now();
    for (int t = 0; t < T; ++t) {
        ctxs[static_cast<std::size_t>(t)] = {&state, t};
        pthread_create(&threads[static_cast<std::size_t>(t)], nullptr, mutex_worker,
                       &ctxs[static_cast<std::size_t>(t)]);
    }
    for (int t = 0; t < T; ++t) {
        pthread_join(threads[static_cast<std::size_t>(t)], nullptr);
    }
    auto m1 = std::chrono::steady_clock::now();
    double t_mutex = elapsed_ms(m0, m1);

    // Fix 2: OpenMP atomic
    double omp_dot = 0.0;
    omp_set_num_threads(T);
    auto o0 = std::chrono::steady_clock::now();
#pragma omp parallel
    {
        double local_p = 0.0;
#pragma omp for schedule(static) nowait
        for (std::size_t i = 0; i < n; ++i) {
            local_p += A[i] * B[i];
        }
#pragma omp atomic
        omp_dot += local_p;
    }
    auto o1 = std::chrono::steady_clock::now();
    double t_omp = elapsed_ms(o0, o1);

    pthread_mutex_destroy(&state.mtx);

    std::cout << "\n--- Summary Timing & Correctness Table ---\n";
    std::cout << std::left << std::setw(22) << "Variant"
              << std::setw(16) << "Result"
              << std::setw(14) << "Time (ms)"
              << "Correctness\n";
    std::cout << std::string(64, '-') << "\n";
    std::cout << std::left << std::setw(22) << "Sequential"
              << std::setw(16) << seq_dot
              << std::setprecision(3) << std::setw(14) << t_seq << "BASELINE\n";
    std::cout << std::left << std::setw(22) << "Buggy (no lock)"
              << std::setprecision(1) << std::setw(16) << state.shared_dot
              << std::setprecision(3) << std::setw(14) << t_racy_last
              << (std::abs(state.shared_dot - seq_dot) < 1e-6 ? "PASS" : "FAIL (RACE)") << "\n";
    std::cout << std::left << std::setw(22) << "Fix 1 (pthread_mutex)"
              << std::setprecision(1) << std::setw(16) << state.mutex_dot
              << std::setprecision(3) << std::setw(14) << t_mutex
              << (std::abs(state.mutex_dot - seq_dot) < 1e-6 ? "PASS" : "FAIL") << "\n";
    std::cout << std::left << std::setw(22) << "Fix 2 (omp atomic)"
              << std::setprecision(1) << std::setw(16) << omp_dot
              << std::setprecision(3) << std::setw(14) << t_omp
              << (std::abs(omp_dot - seq_dot) < 1e-6 ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "Without synchronization, concurrent read-modify-write updates to shared_dot "
              << "interleave and overwrite one another, losing the majority of increments and "
              << "producing non-deterministic wrong answers. Accumulating locally and guarding "
              << "the final merge with pthread_mutex_t or #pragma omp atomic restores exact "
              << "correctness while avoiding per-element lock contention.\n";
    return 0;
}
