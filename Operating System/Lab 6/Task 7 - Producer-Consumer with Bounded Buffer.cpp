#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 7: Producer-Consumer with a Bounded Buffer (C++17)
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

class BoundedBuffer {
public:
    explicit BoundedBuffer(std::size_t capacity)
        : buf_(capacity, 0), in_(0), out_(0), count_(0) {
        pthread_mutex_init(&mtx_, nullptr);
        pthread_cond_init(&not_full_, nullptr);
        pthread_cond_init(&not_empty_, nullptr);
    }

    ~BoundedBuffer() {
        pthread_cond_destroy(&not_empty_);
        pthread_cond_destroy(&not_full_);
        pthread_mutex_destroy(&mtx_);
    }

    void push(long item) {
        pthread_mutex_lock(&mtx_);
        while (count_ == buf_.size()) {
            pthread_cond_wait(&not_full_, &mtx_);
        }
        buf_[in_] = item;
        in_ = (in_ + 1) % buf_.size();
        ++count_;
        pthread_cond_signal(&not_empty_);
        pthread_mutex_unlock(&mtx_);
    }

    long pop() {
        pthread_mutex_lock(&mtx_);
        while (count_ == 0) {
            pthread_cond_wait(&not_empty_, &mtx_);
        }
        long item = buf_[out_];
        out_ = (out_ + 1) % buf_.size();
        --count_;
        pthread_cond_signal(&not_full_);
        pthread_mutex_unlock(&mtx_);
        return item;
    }

private:
    std::vector<long> buf_;
    std::size_t in_;
    std::size_t out_;
    std::size_t count_;
    pthread_mutex_t mtx_;
    pthread_cond_t not_full_;
    pthread_cond_t not_empty_;
};

struct ProducerArgs {
    BoundedBuffer* q;
    long n;
};

struct ConsumerArgs {
    BoundedBuffer* q;
    long long sum;
    long count;
};

void* producer_fn(void* arg) {
    auto* a = static_cast<ProducerArgs*>(arg);
    for (long i = 0; i < a->n; ++i) {
        a->q->push(i);
    }
    a->q->push(-1); // Sentinel
    return nullptr;
}

void* consumer_fn(void* arg) {
    auto* a = static_cast<ConsumerArgs*>(arg);
    a->sum = 0;
    a->count = 0;
    while (true) {
        long x = a->q->pop();
        if (x == -1) break;
        a->sum += x;
        ++a->count;
    }
    return nullptr;
}

} // namespace

int main() {
    const long N = 100000;
    const std::size_t K = 32;

    std::cout << "=== Lab 6 Task 7: Producer-Consumer with Bounded Buffer ===\n";
    std::cout << "Items: " << N << ", Ring buffer capacity K = " << K << "\n\n";

    BoundedBuffer buffer(K);
    ProducerArgs pa{&buffer, N};
    ConsumerArgs ca{&buffer, 0, 0};

    pthread_t prod, cons;
    auto t0 = std::chrono::steady_clock::now();
    pthread_create(&prod, nullptr, producer_fn, &pa);
    pthread_create(&cons, nullptr, consumer_fn, &ca);
    pthread_join(prod, nullptr);
    pthread_join(cons, nullptr);
    auto t1 = std::chrono::steady_clock::now();

    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    long long expected_sum = static_cast<long long>(N) * (N - 1) / 2;
    bool ok = (ca.count == N) && (ca.sum == expected_sum);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Produced/Consumed: " << ca.count << " items\n"
              << "Consumed Sum:      " << ca.sum << " (expected " << expected_sum << ")\n"
              << "Elapsed Time:      " << ms << " ms ("
              << (static_cast<double>(N) / (ms / 1000.0)) << " items/sec)\n"
              << "Correctness:       " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "The fixed-size ring buffer transfers all 100,000 items with zero drops or "
              << "corruption, verified by the exact triangular sum. Using while loops around "
              << "pthread_cond_wait protects against spurious wakeups when the buffer is full "
              << "or empty. Distinct notFull and notEmpty condition variables prevent wakeups "
              << "from blocking progress between producer and consumer.\n";
    return 0;
}
