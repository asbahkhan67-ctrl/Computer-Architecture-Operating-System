#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 8: Three-Stage Pipeline (C++17)
#include <chrono>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

template <typename T>
class BlockingQueue {
public:
    explicit BlockingQueue(std::size_t cap)
        : buf_(cap), in_(0), out_(0), count_(0) {
        pthread_mutex_init(&mtx_, nullptr);
        pthread_cond_init(&not_full_, nullptr);
        pthread_cond_init(&not_empty_, nullptr);
    }

    ~BlockingQueue() {
        pthread_cond_destroy(&not_empty_);
        pthread_cond_destroy(&not_full_);
        pthread_mutex_destroy(&mtx_);
    }

    void put(T item) {
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

    T get() {
        pthread_mutex_lock(&mtx_);
        while (count_ == 0) {
            pthread_cond_wait(&not_empty_, &mtx_);
        }
        T item = buf_[out_];
        out_ = (out_ + 1) % buf_.size();
        --count_;
        pthread_cond_signal(&not_full_);
        pthread_mutex_unlock(&mtx_);
        return item;
    }

private:
    std::vector<T> buf_;
    std::size_t in_;
    std::size_t out_;
    std::size_t count_;
    pthread_mutex_t mtx_;
    pthread_cond_t not_full_;
    pthread_cond_t not_empty_;
};

struct Stage1Args {
    BlockingQueue<long long>* q1;
    long long n;
};

struct Stage2Args {
    BlockingQueue<long long>* q1;
    BlockingQueue<long long>* q2;
};

struct Stage3Args {
    BlockingQueue<long long>* q2;
    long long sum;
    long long count;
};

void* stage1_fn(void* arg) {
    auto* a = static_cast<Stage1Args*>(arg);
    for (long long i = 0; i < a->n; ++i) {
        a->q1->put(i);
    }
    a->q1->put(-1);
    return nullptr;
}

void* stage2_fn(void* arg) {
    auto* a = static_cast<Stage2Args*>(arg);
    while (true) {
        long long x = a->q1->get();
        if (x == -1) {
            a->q2->put(-1);
            break;
        }
        a->q2->put(x * x);
    }
    return nullptr;
}

void* stage3_fn(void* arg) {
    auto* a = static_cast<Stage3Args*>(arg);
    long long s = 0;
    long long cnt = 0;
    while (true) {
        long long y = a->q2->get();
        if (y == -1) break;
        s += y;
        ++cnt;
    }
    a->sum = s;
    a->count = cnt;
    return nullptr;
}

} // namespace

int main() {
    const long long N = 100000;
    const std::size_t K = 64;

    std::cout << "=== Lab 6 Task 8: Three-Stage Pipeline ===\n";
    std::cout << "Stream length N = " << N << ", Queue capacity K = " << K << "\n\n";

    // Sequential baseline
    auto s0 = std::chrono::steady_clock::now();
    volatile long long seq_sum = 0;
    long long local_s = 0;
    for (long long i = 0; i < N; ++i) {
        local_s += i * i;
    }
    seq_sum = local_s;
    auto s1 = std::chrono::steady_clock::now();
    double t_seq = std::chrono::duration<double, std::milli>(s1 - s0).count();

    // Pipeline execution
    BlockingQueue<long long> q1(K), q2(K);
    Stage1Args a1{&q1, N};
    Stage2Args a2{&q1, &q2};
    Stage3Args a3{&q2, 0, 0};

    pthread_t th1, th2, th3;
    auto p0 = std::chrono::steady_clock::now();
    pthread_create(&th1, nullptr, stage1_fn, &a1);
    pthread_create(&th2, nullptr, stage2_fn, &a2);
    pthread_create(&th3, nullptr, stage3_fn, &a3);
    pthread_join(th1, nullptr);
    pthread_join(th2, nullptr);
    pthread_join(th3, nullptr);
    auto p1 = std::chrono::steady_clock::now();
    double t_pipe = std::chrono::duration<double, std::milli>(p1 - p0).count();

    long long expected = seq_sum;
    bool ok = (a3.sum == expected) && (a3.count == N);

    std::cout << std::fixed << std::setprecision(3);
    std::cout << std::left << std::setw(20) << "Mode"
              << std::setw(14) << "Time (ms)"
              << std::setw(18) << "Throughput (it/s)"
              << "Result\n";
    std::cout << std::string(68, '-') << "\n";
    std::cout << std::left << std::setw(20) << "Sequential loop"
              << std::setw(14) << t_seq
              << std::setw(18) << std::setprecision(0) << (N / (t_seq / 1000.0))
              << expected << "\n";
    std::cout << std::left << std::setw(20) << "3-Stage pipeline"
              << std::setprecision(3) << std::setw(14) << t_pipe
              << std::setw(18) << std::setprecision(0) << (N / (t_pipe / 1000.0))
              << a3.sum << "\n";
    std::cout << "\nCorrectness: " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "The three-stage pipeline computes the exact sum of squares (" << a3.sum
              << ") and shuts down cleanly via the -1 sentinel propagated from Stage 1 to Stage 3. "
              << "Because each item here performs only one integer multiplication and addition, "
              << "mutex/condvar synchronization per element dominates over the arithmetic work, "
              << "making the tight sequential loop faster. Pipelines achieve net speedup when "
              << "per-stage work is substantially heavier than queue synchronization cost.\n";
    return 0;
}
