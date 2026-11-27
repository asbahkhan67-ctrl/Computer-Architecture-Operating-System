#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 17: Thread Creation and Scalability Limits (KLT vs. 500k ULT Fibers) (C++17)
#include <cerrno>
#include <chrono>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <new>
#include <pthread.h>
#include <ucontext.h>
#include <vector>

using namespace std;

namespace {

constexpr int TARGET_ULT_FIBERS = 500000;
constexpr size_t MIN_FIBER_STACK = 4096;

pthread_mutex_t g_mtx = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t g_cv = PTHREAD_COND_INITIALIZER;
bool g_stop = false;

void* dummy_idle_routine(void*) {
    pthread_mutex_lock(&g_mtx);
    while (!g_stop) {
        pthread_cond_wait(&g_cv, &g_mtx);
    }
    pthread_mutex_unlock(&g_mtx);
    return nullptr;
}

struct UltDescriptor {
    int id;
    ucontext_t ctx;
    char* stack;
};

} // namespace

int main() {
    cout << "=== Lab 7 Task 17: Thread Creation and Scalability Limits ===\n\n";

    // 1. KLT stress test until pthread_create hits kernel/ulimit cap
    cout << "--- Stress Test 1: Kernel-Level Threads (pthreads) ---\n";
    vector<pthread_t> klts;
    klts.reserve(16384);

    auto k0 = chrono::steady_clock::now();
    int fail_err = 0;
    while (true) {
        pthread_t t;
        int rc = pthread_create(&t, nullptr, dummy_idle_routine, nullptr);
        if (rc != 0) {
            fail_err = rc;
            break;
        }
        klts.push_back(t);
    }
    auto k1 = chrono::steady_clock::now();
    double klt_ms = chrono::duration<double, milli>(k1 - k0).count();

    cout << "KLT allocation hit limit at: " << klts.size() << " concurrent threads ("
         << strerror(fail_err) << ") in " << fixed << setprecision(2) << klt_ms << " ms\n";

    pthread_mutex_lock(&g_mtx);
    g_stop = true;
    pthread_cond_broadcast(&g_cv);
    pthread_mutex_unlock(&g_mtx);
    for (pthread_t t : klts) {
        pthread_join(t, nullptr);
    }
    klts.clear();
    cout << "Cleaned up all kernel threads.\n\n";

    // 2. ULT stress test: allocate 500,000 lightweight 4 KB fiber descriptors
    cout << "--- Stress Test 2: User-Level Thread Descriptors (500,000 x 4 KB) ---\n";
    vector<UltDescriptor> ults(TARGET_ULT_FIBERS);
    int ult_created = 0;

    auto u0 = chrono::steady_clock::now();
    for (int i = 0; i < TARGET_ULT_FIBERS; ++i) {
        char* stk = new (nothrow) char[MIN_FIBER_STACK];
        if (!stk) break;
        ults[static_cast<size_t>(i)].id = i;
        ults[static_cast<size_t>(i)].stack = stk;
        ++ult_created;
    }
    auto u1 = chrono::steady_clock::now();
    double ult_ms = chrono::duration<double, milli>(u1 - u0).count();

    cout << "Successfully allocated " << ult_created << " ULT fibers in heap in "
         << ult_ms << " ms (" << (static_cast<double>(ult_created) * MIN_FIBER_STACK) / (1024.0 * 1024.0)
         << " MiB virtual stack space)\n";

    for (int i = 0; i < ult_created; ++i) {
        delete[] ults[static_cast<size_t>(i)].stack;
    }

    bool ok = (ult_created == TARGET_ULT_FIBERS);
    cout << "\nComparison Check: " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
