#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 2: Kernel Task ID vs. POSIX Thread Handle (C++17)
#include <cstdlib>
#include <iostream>
#include <pthread.h>
#include <sys/syscall.h>
#include <unistd.h>

using namespace std;

namespace {

int g_sleep_secs = 20;
pthread_mutex_t g_io_mtx = PTHREAD_MUTEX_INITIALIZER;

void* thread_inspect(void*) {
    pthread_t posix_id = pthread_self();
    long kernel_tid = syscall(SYS_gettid);
    pid_t process_pid = getpid();

    pthread_mutex_lock(&g_io_mtx);
    cout << "PID: " << process_pid
         << " | POSIX ID: " << posix_id
         << " | Kernel TID: " << kernel_tid << "\n" << flush;
    pthread_mutex_unlock(&g_io_mtx);

    sleep(static_cast<unsigned int>(g_sleep_secs));
    return nullptr;
}

} // namespace

int main(int argc, char* argv[]) {
    if (argc > 1) {
        int v = atoi(argv[1]);
        if (v >= 1) g_sleep_secs = v;
    }

    cout << "=== Lab 7 Task 2: Kernel Task ID vs. POSIX Thread Handle ===\n";
    cout << "Main PID: " << getpid() << " | Main Kernel TID: " << syscall(SYS_gettid)
         << " (workers sleeping " << g_sleep_secs << "s; inspect with: ps -eLf | grep task02)\n\n";

    pthread_t threads[3];
    for (int i = 0; i < 3; ++i) {
        pthread_create(&threads[i], nullptr, thread_inspect, nullptr);
    }
    for (int i = 0; i < 3; ++i) {
        pthread_join(threads[i], nullptr);
    }

    cout << "\nJoined all 3 inspection threads cleanly.\n";
    return 0;
}
