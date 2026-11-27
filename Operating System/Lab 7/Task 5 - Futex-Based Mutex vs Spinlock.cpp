#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 5: Synchronization Primitives: Futex-Based Mutex vs. Spinlock (C++17)
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

using namespace std;

namespace {

constexpr int NUM_THREADS = 8;
constexpr int ITERS_PER_THREAD = 1000000;

long long g_counter = 0;
pthread_mutex_t g_mutex;
pthread_spinlock_t g_spin;

void* thread_increment_mutex(void*) {
    for (int i = 0; i < ITERS_PER_THREAD; ++i) {
        pthread_mutex_lock(&g_mutex);
        ++g_counter;
        pthread_mutex_unlock(&g_mutex);
    }
    return nullptr;
}

void* thread_increment_spin(void*) {
    for (int i = 0; i < ITERS_PER_THREAD; ++i) {
        pthread_spin_lock(&g_spin);
        ++g_counter;
        pthread_spin_unlock(&g_spin);
    }
    return nullptr;
}

double run_benchmark(void* (*fn)(void*)) {
    g_counter = 0;
    vector<pthread_t> threads(NUM_THREADS);
    auto t0 = chrono::steady_clock::now();
    for (int t = 0; t < NUM_THREADS; ++t) {
        pthread_create(&threads[static_cast<size_t>(t)], nullptr, fn, nullptr);
    }
    for (int t = 0; t < NUM_THREADS; ++t) {
        pthread_join(threads[static_cast<size_t>(t)], nullptr);
    }
    auto t1 = chrono::steady_clock::now();
    return chrono::duration<double, milli>(t1 - t0).count();
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 5: Futex-Based Mutex vs. Spinlock ===\n";
    cout << "Threads: " << NUM_THREADS << ", Increments/thread: " << ITERS_PER_THREAD << "\n\n";

    pthread_mutex_init(&g_mutex, nullptr);
    pthread_spin_init(&g_spin, PTHREAD_PROCESS_PRIVATE);

    const long long expected = static_cast<long long>(NUM_THREADS) * ITERS_PER_THREAD;

    double mutex_ms = run_benchmark(thread_increment_mutex);
    long long mutex_count = g_counter;

    double spin_ms = run_benchmark(thread_increment_spin);
    long long spin_count = g_counter;

    pthread_spin_destroy(&g_spin);
    pthread_mutex_destroy(&g_mutex);

    cout << fixed << setprecision(2);
    cout << "Mutex Execution Elapsed:    " << mutex_ms << " ms ("
         << (mutex_ms * 1e6 / static_cast<double>(expected)) << " ns/op) | count="
         << mutex_count << " (" << (mutex_count == expected ? "PASS" : "FAIL") << ")\n";
    cout << "Spinlock Execution Elapsed: " << spin_ms << " ms ("
         << (spin_ms * 1e6 / static_cast<double>(expected)) << " ns/op) | count="
         << spin_count << " (" << (spin_count == expected ? "PASS" : "FAIL") << ")\n";

    return 0;
}
