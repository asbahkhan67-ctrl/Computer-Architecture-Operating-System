#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 7: Thread-Specific Data & Thread-Local Storage (TLS) (C++17)
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <pthread.h>
#include <unistd.h>

using namespace std;

namespace {

thread_local int private_counter = 0;
pthread_key_t g_tls_key;
pthread_mutex_t g_print_mtx = PTHREAD_MUTEX_INITIALIZER;

void* worker(void* arg) {
    int id = *static_cast<int*>(arg);
    private_counter += id * 10;

    auto* buffer = static_cast<char*>(malloc(256));
    snprintf(buffer, 256, "Log entry for thread %d", id);
    pthread_setspecific(g_tls_key, buffer);

    usleep(10000 * static_cast<unsigned int>(id));
    private_counter += 1;

    auto* retrieved_buf = static_cast<char*>(pthread_getspecific(g_tls_key));
    pthread_mutex_lock(&g_print_mtx);
    cout << "Thread: " << id
         << " | TLS Data: \"" << retrieved_buf << "\""
         << " | thread_local private_counter: " << private_counter << "\n";
    pthread_mutex_unlock(&g_print_mtx);

    free(retrieved_buf);
    return nullptr;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 7: Thread-Specific Data & Thread-Local Storage ===\n";

    pthread_key_create(&g_tls_key, nullptr);

    pthread_t threads[4];
    int ids[4] = {1, 2, 3, 4};
    for (int i = 0; i < 4; ++i) {
        pthread_create(&threads[i], nullptr, worker, &ids[i]);
    }
    for (int i = 0; i < 4; ++i) {
        pthread_join(threads[i], nullptr);
    }

    pthread_key_delete(g_tls_key);
    cout << "Main thread private_counter remains untouched: " << private_counter << "\n";
    return 0;
}
