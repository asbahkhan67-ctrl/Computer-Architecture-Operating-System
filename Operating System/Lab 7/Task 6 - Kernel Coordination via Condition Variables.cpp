#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 6: Kernel Coordination via Condition Variables (C++17)
#include <iostream>
#include <pthread.h>

using namespace std;

namespace {

constexpr int CAPACITY = 16;
constexpr int TOTAL_ITEMS = 50000;

int g_buffer[CAPACITY];
int g_buf_count = 0;
int g_in = 0;
int g_out = 0;
pthread_mutex_t g_mtx = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t g_not_full = PTHREAD_COND_INITIALIZER;
pthread_cond_t g_not_empty = PTHREAD_COND_INITIALIZER;

void producer_enqueue(int item) {
    pthread_mutex_lock(&g_mtx);
    while (g_buf_count == CAPACITY) {
        pthread_cond_wait(&g_not_full, &g_mtx);
    }
    g_buffer[g_in] = item;
    g_in = (g_in + 1) % CAPACITY;
    ++g_buf_count;
    pthread_cond_signal(&g_not_empty);
    pthread_mutex_unlock(&g_mtx);
}

int consumer_dequeue() {
    pthread_mutex_lock(&g_mtx);
    while (g_buf_count == 0) {
        pthread_cond_wait(&g_not_empty, &g_mtx);
    }
    int item = g_buffer[g_out];
    g_out = (g_out + 1) % CAPACITY;
    --g_buf_count;
    pthread_cond_signal(&g_not_full);
    pthread_mutex_unlock(&g_mtx);
    return item;
}

void* producer_thread(void*) {
    for (int i = 1; i <= TOTAL_ITEMS; ++i) {
        producer_enqueue(i);
    }
    producer_enqueue(-1); // End-of-stream sentinel
    return nullptr;
}

void* consumer_thread(void* arg) {
    auto* sum_out = static_cast<long long*>(arg);
    long long s = 0;
    while (true) {
        int x = consumer_dequeue();
        if (x == -1) break;
        s += x;
    }
    *sum_out = s;
    return nullptr;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 6: Kernel Coordination via Condition Variables ===\n";

    pthread_t prod, cons;
    long long consumed_sum = 0;

    pthread_create(&prod, nullptr, producer_thread, nullptr);
    pthread_create(&cons, nullptr, consumer_thread, &consumed_sum);
    pthread_join(prod, nullptr);
    pthread_join(cons, nullptr);

    long long expected = static_cast<long long>(TOTAL_ITEMS) * (TOTAL_ITEMS + 1) / 2;
    cout << "Transferred " << TOTAL_ITEMS << " items through capacity-" << CAPACITY << " buffer.\n";
    cout << "Checksum: " << consumed_sum << " (expected " << expected << ") -> "
         << (consumed_sum == expected ? "PASS" : "FAIL") << "\n";

    pthread_cond_destroy(&g_not_empty);
    pthread_cond_destroy(&g_not_full);
    pthread_mutex_destroy(&g_mtx);
    return 0;
}
