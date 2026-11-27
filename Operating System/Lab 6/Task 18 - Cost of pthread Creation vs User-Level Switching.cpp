#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 18: Cost of pthread Creation vs. User-Level Switching (C++17)
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <ucontext.h>
#include <vector>

namespace {

constexpr int ITERS = 10000;
constexpr std::size_t STACK_SZ = 32768;

void* empty_pthread(void*) {
    return nullptr;
}

ucontext_t g_main_ctx, g_c1, g_c2;
volatile int g_swaps_done = 0;

void c1_body() {
    for (int i = 0; i < ITERS; ++i) {
        swapcontext(&g_c1, &g_c2);
    }
    g_swaps_done = ITERS;
    setcontext(&g_main_ctx);
}

void c2_body() {
    while (true) {
        swapcontext(&g_c2, &g_c1);
    }
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 18: Cost of pthread Creation vs. User-Level Switching ===\n";
    std::cout << "Iterations: " << ITERS << "\n\n";

    // 1. pthread create + join
    auto p0 = std::chrono::steady_clock::now();
    for (int i = 0; i < ITERS; ++i) {
        pthread_t th;
        pthread_create(&th, nullptr, empty_pthread, nullptr);
        pthread_join(th, nullptr);
    }
    auto p1 = std::chrono::steady_clock::now();
    double t_pthread_ms = std::chrono::duration<double, std::milli>(p1 - p0).count();
    double t_pthread_ns = std::chrono::duration<double, std::nano>(p1 - p0).count();

    // 2. 10,000 user-level context switch pairs (c1->c2 and c2->c1)
    std::vector<char> stk1(STACK_SZ), stk2(STACK_SZ);
    getcontext(&g_c1);
    g_c1.uc_stack.ss_sp = stk1.data();
    g_c1.uc_stack.ss_size = STACK_SZ;
    g_c1.uc_link = &g_main_ctx;
    makecontext(&g_c1, c1_body, 0);

    getcontext(&g_c2);
    g_c2.uc_stack.ss_sp = stk2.data();
    g_c2.uc_stack.ss_size = STACK_SZ;
    g_c2.uc_link = &g_main_ctx;
    makecontext(&g_c2, c2_body, 0);

    auto u0 = std::chrono::steady_clock::now();
    swapcontext(&g_main_ctx, &g_c1);
    auto u1 = std::chrono::steady_clock::now();
    double t_uctx_ms = std::chrono::duration<double, std::milli>(u1 - u0).count();
    double t_uctx_ns = std::chrono::duration<double, std::nano>(u1 - u0).count();

    double ratio = t_pthread_ns / t_uctx_ns;
    bool ok = (g_swaps_done == ITERS) && (t_pthread_ns > t_uctx_ns);

    std::cout << std::fixed << std::setprecision(3);
    std::cout << std::left << std::setw(28) << "Operation (x10,000)"
              << std::setw(14) << "Total (ms)"
              << std::setw(16) << "Per-iter (ns)" << "\n";
    std::cout << std::string(58, '-') << "\n";
    std::cout << std::left << std::setw(28) << "pthread_create + join"
              << std::setw(14) << t_pthread_ms
              << std::setprecision(1) << std::setw(16) << (t_pthread_ns / ITERS) << "\n";
    std::cout << std::left << std::setw(28) << "swapcontext round-trip"
              << std::setprecision(3) << std::setw(14) << t_uctx_ms
              << std::setprecision(1) << std::setw(16) << (t_uctx_ns / ITERS) << "\n";

    std::cout << "\nSpeedup / Ratio (t_pthread / t_uctx): " << std::setprecision(2) << ratio
              << "x | Check: " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "Creating and joining 10,000 pthreads is orders of magnitude slower than 10,000 "
              << "user-level context switches. Each pthread lifecycle requires mmap stack "
              << "allocation, clone()/futex system calls into kernel space, kernel task_struct "
              << "setup, and teardown. By contrast, swapcontext() only saves/restores CPU registers "
              << "and signal masks purely in user space without kernel scheduling transitions.\n";
    return 0;
}
