#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 1: Basic POSIX Thread Lifecycle (C++17)
#include <cassert>
#include <cmath>
#include <iostream>
#include <pthread.h>

using namespace std;

namespace {

pthread_mutex_t g_print_mtx = PTHREAD_MUTEX_INITIALIZER;

double perform_light_computation(int seed) {
    double acc = 0.0;
    for (int k = 1; k <= 10000; ++k) {
        acc += sqrt(static_cast<double>(seed * k));
    }
    return acc;
}

void* worker_routine(void* arg) {
    int thread_arg = *static_cast<int*>(arg);
    pthread_t tid = pthread_self();

    pthread_mutex_lock(&g_print_mtx);
    cout << "Worker executing with Arg: " << thread_arg
         << ", POSIX TID: " << tid << "\n";
    pthread_mutex_unlock(&g_print_mtx);

    volatile double res = perform_light_computation(thread_arg);
    (void)res;
    pthread_exit(nullptr);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 1: Basic POSIX Thread Lifecycle ===\n";

    pthread_t threads[4];
    int args[4] = {1, 2, 3, 4};

    for (int i = 0; i < 4; ++i) {
        int status = pthread_create(&threads[i], nullptr, worker_routine, &args[i]);
        assert(status == 0);
    }

    for (int i = 0; i < 4; ++i) {
        int status = pthread_join(threads[i], nullptr);
        assert(status == 0);
    }

    cout << "All kernel worker threads completed successfully.\n";
    return 0;
}
