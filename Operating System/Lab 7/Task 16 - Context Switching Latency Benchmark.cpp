#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 16: Context Switching Latency Benchmark (ULT vs. Pipe Ping-Pong KLT) (C++17)
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <sched.h>
#include <ucontext.h>
#include <unistd.h>

using namespace std;

namespace {

constexpr int ULT_SWITCHES = 1000000; // 1,000,000 swapcontext calls
constexpr int KLT_ROUND_TRIPS = 50000; // 50,000 ping-pongs = 100,000 KLT switches
constexpr size_t STK_SIZE = 32768;

ucontext_t g_main_ctx, g_ctx1, g_ctx2;
char g_stk1[STK_SIZE], g_stk2[STK_SIZE];

void ult1_fn() {
    for (int i = 0; i < ULT_SWITCHES / 2; ++i) {
        swapcontext(&g_ctx1, &g_ctx2);
    }
    setcontext(&g_main_ctx);
}

void ult2_fn() {
    while (true) {
        swapcontext(&g_ctx2, &g_ctx1);
    }
}

struct PipePair {
    int p1[2]; // A -> B
    int p2[2]; // B -> A
};

void pin_to_cpu0() {
    cpu_set_t set;
    CPU_ZERO(&set);
    CPU_SET(0, &set);
    pthread_setaffinity_np(pthread_self(), sizeof(set), &set);
}

void* klt_ping(void* arg) {
    pin_to_cpu0();
    auto* pp = static_cast<PipePair*>(arg);
    char byte = 'P';
    for (int i = 0; i < KLT_ROUND_TRIPS; ++i) {
        ssize_t w = write(pp->p1[1], &byte, 1);
        ssize_t r = read(pp->p2[0], &byte, 1);
        (void)w;
        (void)r;
    }
    return nullptr;
}

void* klt_pong(void* arg) {
    pin_to_cpu0();
    auto* pp = static_cast<PipePair*>(arg);
    char byte = 0;
    for (int i = 0; i < KLT_ROUND_TRIPS; ++i) {
        ssize_t r = read(pp->p1[0], &byte, 1);
        ssize_t w = write(pp->p2[1], &byte, 1);
        (void)r;
        (void)w;
    }
    return nullptr;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 16: Context Switching Latency Benchmark ===\n\n";

    // 1. ULT swapcontext benchmark
    getcontext(&g_ctx1);
    g_ctx1.uc_stack.ss_sp = g_stk1;
    g_ctx1.uc_stack.ss_size = STK_SIZE;
    g_ctx1.uc_link = &g_main_ctx;
    makecontext(&g_ctx1, ult1_fn, 0);

    getcontext(&g_ctx2);
    g_ctx2.uc_stack.ss_sp = g_stk2;
    g_ctx2.uc_stack.ss_size = STK_SIZE;
    g_ctx2.uc_link = &g_main_ctx;
    makecontext(&g_ctx2, ult2_fn, 0);

    auto u0 = chrono::steady_clock::now();
    swapcontext(&g_main_ctx, &g_ctx1);
    auto u1 = chrono::steady_clock::now();
    double ult_ns = chrono::duration<double, nano>(u1 - u0).count();
    double avg_ult_ns = ult_ns / static_cast<double>(ULT_SWITCHES);

    // 2. KLT pipe ping-pong benchmark (both threads pinned to CPU 0)
    PipePair pp{};
    if (pipe(pp.p1) != 0 || pipe(pp.p2) != 0) return 1;

    pthread_t ta, tb;
    auto k0 = chrono::steady_clock::now();
    pthread_create(&ta, nullptr, klt_ping, &pp);
    pthread_create(&tb, nullptr, klt_pong, &pp);
    pthread_join(ta, nullptr);
    pthread_join(tb, nullptr);
    auto k1 = chrono::steady_clock::now();

    close(pp.p1[0]);
    close(pp.p1[1]);
    close(pp.p2[0]);
    close(pp.p2[1]);

    double klt_ns = chrono::duration<double, nano>(k1 - k0).count();
    double total_klt_switches = static_cast<double>(KLT_ROUND_TRIPS) * 2.0;
    double avg_klt_ns = klt_ns / total_klt_switches;

    cout << fixed << setprecision(2);
    cout << "ULT Switches (" << ULT_SWITCHES << "x):      " << (ult_ns / 1e6) << " ms | Avg: "
         << avg_ult_ns << " ns/switch\n";
    cout << "KLT Switches (" << (KLT_ROUND_TRIPS * 2) << "x):      " << (klt_ns / 1e6) << " ms | Avg: "
         << avg_klt_ns << " ns/switch\n";
    cout << "KLT / ULT Switch Ratio:         " << (avg_klt_ns / avg_ult_ns) << "x\n";
    return 0;
}
