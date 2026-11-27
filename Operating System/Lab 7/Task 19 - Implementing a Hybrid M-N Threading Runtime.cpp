#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 19: Implementing a Hybrid M:N Threading Runtime (C++17)
#include <atomic>
#include <chrono>
#include <cstdlib>
#include <deque>
#include <iostream>
#include <pthread.h>
#include <sys/syscall.h>
#include <ucontext.h>
#include <unistd.h>

using namespace std;

namespace {

constexpr int M_WORKERS = 4;
constexpr int N_FIBERS = 10000;
constexpr size_t FIBER_STK_SIZE = 16384;

struct ULT_Task {
    int id = 0;
    bool shutdown = false;
    ucontext_t ctx{};
    void* stack = nullptr;
};

class ThreadSafeQueue {
public:
    void push(ULT_Task* t) {
        pthread_mutex_lock(&mtx_);
        q_.push_back(t);
        pthread_cond_signal(&cv_);
        pthread_mutex_unlock(&mtx_);
    }

    ULT_Task* pop() {
        pthread_mutex_lock(&mtx_);
        while (q_.empty()) {
            pthread_cond_wait(&cv_, &mtx_);
        }
        ULT_Task* t = q_.front();
        q_.pop_front();
        pthread_mutex_unlock(&mtx_);
        return t;
    }

private:
    deque<ULT_Task*> q_;
    pthread_mutex_t mtx_ = PTHREAD_MUTEX_INITIALIZER;
    pthread_cond_t cv_ = PTHREAD_COND_INITIALIZER;
};

ThreadSafeQueue g_task_queue;
atomic<int> g_completed_fibers{0};
atomic<long long> g_checksum{0};
int g_worker_counts[M_WORKERS]{};

struct WorkerCtx {
    int worker_id;
    long kernel_tid;
    ucontext_t worker_ctx;
    ULT_Task* active_task;
};

thread_local WorkerCtx* tl_worker = nullptr;

void task_routine() {
    ULT_Task* t = tl_worker->active_task;
    // Lightweight user-space work per fiber
    g_checksum.fetch_add(t->id, memory_order_relaxed);
    g_completed_fibers.fetch_add(1, memory_order_relaxed);
    setcontext(&tl_worker->worker_ctx);
}

void execute_user_fiber(ULT_Task* task) {
    tl_worker->active_task = task;
    getcontext(&task->ctx);
    task->ctx.uc_stack.ss_sp = task->stack;
    task->ctx.uc_stack.ss_size = FIBER_STK_SIZE;
    task->ctx.uc_link = &tl_worker->worker_ctx;
    makecontext(&task->ctx, task_routine, 0);
    swapcontext(&tl_worker->worker_ctx, &task->ctx);
}

void* kernel_worker_loop(void* arg) {
    auto* w = static_cast<WorkerCtx*>(arg);
    tl_worker = w;
    w->kernel_tid = syscall(SYS_gettid);

    while (true) {
        ULT_Task* task = g_task_queue.pop();
        if (task->shutdown) {
            delete task;
            break;
        }
        execute_user_fiber(task);
        ++g_worker_counts[w->worker_id];
        free(task->stack);
        delete task;
    }
    return nullptr;
}

ULT_Task* create_new_fiber(int id) {
    auto* t = new ULT_Task();
    t->id = id;
    t->shutdown = false;
    t->stack = malloc(FIBER_STK_SIZE);
    return t;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 19: Hybrid M:N Threading Runtime (" << M_WORKERS
         << " KLTs x " << N_FIBERS << " Fibers) ===\n\n";

    pthread_t workers[M_WORKERS];
    WorkerCtx wctx[M_WORKERS]{};

    auto t0 = chrono::steady_clock::now();
    for (int i = 0; i < M_WORKERS; ++i) {
        wctx[i].worker_id = i;
        pthread_create(&workers[i], nullptr, kernel_worker_loop, &wctx[i]);
    }

    for (int j = 1; j <= N_FIBERS; ++j) {
        g_task_queue.push(create_new_fiber(j));
    }
    for (int i = 0; i < M_WORKERS; ++i) {
        auto* stop = new ULT_Task();
        stop->shutdown = true;
        g_task_queue.push(stop);
    }

    for (int i = 0; i < M_WORKERS; ++i) {
        pthread_join(workers[i], nullptr);
        cout << "Kernel Worker " << i << " (TID=" << wctx[i].kernel_tid
             << ") executed " << g_worker_counts[i] << " fibers\n";
    }
    auto t1 = chrono::steady_clock::now();
    double ms = chrono::duration<double, milli>(t1 - t0).count();

    long long expected_sum = static_cast<long long>(N_FIBERS) * (N_FIBERS + 1) / 2;
    bool ok = (g_completed_fibers.load() == N_FIBERS) && (g_checksum.load() == expected_sum);

    cout << "\nCompleted fibers: " << g_completed_fibers.load() << "/" << N_FIBERS
         << " | Checksum: " << g_checksum.load() << " (expected " << expected_sum << ")"
         << " | Time: " << ms << " ms -> " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
