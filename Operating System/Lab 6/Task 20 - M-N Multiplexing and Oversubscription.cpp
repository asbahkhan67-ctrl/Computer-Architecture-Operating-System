#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 20: M:N Multiplexing, Oversubscription, and Starvation (C++17)
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <set>
#include <sys/syscall.h>
#include <ucontext.h>
#include <unistd.h>
#include <vector>

namespace {

constexpr int TOTAL_ULTS = 20;
constexpr int NUM_CARRIERS = 2;
constexpr int TURNS_PER_ULT = 3;
constexpr std::size_t STACK_SZ = 32768;

struct Fiber {
    int id = 0;
    int turns = 0;
    bool greedy = false;
    bool finished = false;
    ucontext_t ctx{};
    std::vector<char> stack;
};

struct CarrierState {
    int carrier_id = 0;
    long kernel_tid = 0;
    ucontext_t carrier_ctx{};
    std::vector<Fiber*> fibers;
    std::size_t cur_idx = 0;
    std::atomic<int>* total_turns = nullptr;
};

thread_local CarrierState* tl_carrier = nullptr;
pthread_mutex_t g_log_mtx = PTHREAD_MUTEX_INITIALIZER;

void fiber_entry() {
    CarrierState* c = tl_carrier;
    Fiber* f = c->fibers[c->cur_idx];

    if (f->greedy) {
        // Greedy user thread loops 250 ms without calling yield() -> starves siblings
        auto start = std::chrono::steady_clock::now();
        volatile double sink = 0.0;
        while (std::chrono::duration<double, std::milli>(
                   std::chrono::steady_clock::now() - start)
                   .count() < 250.0) {
            sink += std::sqrt(12345.67);
        }
        ++f->turns;
        c->total_turns->fetch_add(1);
        f->finished = true;
        setcontext(&c->carrier_ctx);
    }

    for (int t = 1; t <= TURNS_PER_ULT; ++t) {
        ++f->turns;
        c->total_turns->fetch_add(1);
        if (t == 1) {
            pthread_mutex_lock(&g_log_mtx);
            std::cout << "  ULT " << std::setw(2) << f->id
                      << " running on Carrier " << c->carrier_id
                      << " (Kernel TID=" << c->kernel_tid << ")\n";
            pthread_mutex_unlock(&g_log_mtx);
        }
        if (t < TURNS_PER_ULT) {
            swapcontext(&f->ctx, &c->carrier_ctx);
        }
    }
    f->finished = true;
    setcontext(&c->carrier_ctx);
}

void* carrier_thread_fn(void* arg) {
    auto* c = static_cast<CarrierState*>(arg);
    tl_carrier = c;
    c->kernel_tid = syscall(SYS_gettid);

    for (Fiber* f : c->fibers) {
        f->stack.assign(STACK_SZ, 0);
        getcontext(&f->ctx);
        f->ctx.uc_stack.ss_sp = f->stack.data();
        f->ctx.uc_stack.ss_size = STACK_SZ;
        f->ctx.uc_link = &c->carrier_ctx;
        makecontext(&f->ctx, fiber_entry, 0);
    }

    bool any_left = true;
    while (any_left) {
        any_left = false;
        for (std::size_t idx = 0; idx < c->fibers.size(); ++idx) {
            if (!c->fibers[idx]->finished) {
                any_left = true;
                c->cur_idx = idx;
                swapcontext(&c->carrier_ctx, &c->fibers[idx]->ctx);
            }
        }
    }
    return nullptr;
}

struct CpuWorkArgs {
    long iterations;
    double result;
};

void* cpu_bound_worker(void* arg) {
    auto* a = static_cast<CpuWorkArgs*>(arg);
    double acc = 0.0;
    for (long i = 1; i <= a->iterations; ++i) {
        acc += std::sqrt(static_cast<double>(i));
    }
    a->result = acc;
    return nullptr;
}

double run_cpu_threads(int num_threads, long total_iters) {
    std::vector<pthread_t> threads(static_cast<std::size_t>(num_threads));
    std::vector<CpuWorkArgs> args(static_cast<std::size_t>(num_threads));
    long per_thread = total_iters / num_threads;

    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < num_threads; ++i) {
        args[static_cast<std::size_t>(i)] = {per_thread, 0.0};
        pthread_create(&threads[static_cast<std::size_t>(i)], nullptr, cpu_bound_worker,
                       &args[static_cast<std::size_t>(i)]);
    }
    for (int i = 0; i < num_threads; ++i) {
        pthread_join(threads[static_cast<std::size_t>(i)], nullptr);
    }
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 20: M:N Multiplexing, Oversubscription & Starvation ===\n\n";

    // (a) M:N Multiplexing: 20 ULTs on 2 carrier pthreads
    std::cout << "--- Part (a): 20 ULTs Multiplexed onto 2 Carrier Pthreads ---\n";
    std::vector<Fiber> fibers(TOTAL_ULTS);
    CarrierState carriers[NUM_CARRIERS];
    std::atomic<int> total_turns{0};

    for (int j = 0; j < NUM_CARRIERS; ++j) {
        carriers[j].carrier_id = j;
        carriers[j].total_turns = &total_turns;
    }
    for (int i = 0; i < TOTAL_ULTS; ++i) {
        fibers[static_cast<std::size_t>(i)].id = i;
        carriers[i % NUM_CARRIERS].fibers.push_back(&fibers[static_cast<std::size_t>(i)]);
    }

    pthread_t cth[NUM_CARRIERS];
    for (int j = 0; j < NUM_CARRIERS; ++j) {
        pthread_create(&cth[j], nullptr, carrier_thread_fn, &carriers[j]);
    }
    for (int j = 0; j < NUM_CARRIERS; ++j) {
        pthread_join(cth[j], nullptr);
    }

    std::set<long> kernel_tids = {carriers[0].kernel_tid, carriers[1].kernel_tid};
    bool mn_ok = (total_turns.load() == TOTAL_ULTS * TURNS_PER_ULT) && (kernel_tids.size() == 2);
    std::cout << "Completed " << TOTAL_ULTS << " ULTs (" << total_turns.load()
              << " total turns) on " << kernel_tids.size() << " kernel threads: "
              << (mn_ok ? "PASS" : "FAIL") << "\n\n";

    // (b) Oversubscription: nproc vs 4 * nproc
    std::cout << "--- Part (b): CPU Oversubscription (nproc vs 4*nproc) ---\n";
    long nproc = sysconf(_SC_NPROCESSORS_ONLN);
    if (nproc < 1) nproc = 4;
    const long total_work = 120000000L;
    double t_ok = run_cpu_threads(static_cast<int>(nproc), total_work);
    double t_over = run_cpu_threads(static_cast<int>(4 * nproc), total_work);
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "nproc = " << nproc << " -> t_ok = " << t_ok << " ms\n";
    std::cout << "4*nproc = " << (4 * nproc) << " -> t_over = " << t_over
              << " ms (ratio t_over/t_ok = " << (t_over / t_ok) << "x)\n\n";

    // (c) Starvation: greedy ULT without yield blocks siblings on its carrier
    std::cout << "--- Part (c): Non-yielding ULT Starves Siblings ---\n";
    std::vector<Fiber> starv_fibers(3);
    starv_fibers[0].id = 0;
    starv_fibers[0].greedy = true;
    starv_fibers[1].id = 1;
    starv_fibers[2].id = 2;

    CarrierState single_carrier;
    single_carrier.carrier_id = 0;
    std::atomic<int> st_turns{0};
    single_carrier.total_turns = &st_turns;
    for (auto& f : starv_fibers) single_carrier.fibers.push_back(&f);

    auto s0 = std::chrono::steady_clock::now();
    pthread_t sth;
    pthread_create(&sth, nullptr, carrier_thread_fn, &single_carrier);
    pthread_join(sth, nullptr);
    auto s1 = std::chrono::steady_clock::now();
    double st_ms = std::chrono::duration<double, std::milli>(s1 - s0).count();
    std::cout << "Greedy ULT 0 held carrier continuously for " << st_ms
              << " ms before siblings 1 & 2 could run.\n";

    std::cout << "\nConclusion:\n"
              << "Multiplexing 20 user threads across 2 carrier pthreads executes all 20 tasks "
              << "while consuming only 2 kernel TIDs. Oversubscribing CPU-bound pthreads to 4*nproc "
              << "adds creation and preemptive scheduling overhead without extra core capacity. "
              << "Finally, cooperative M:N scheduling relies on yielding: a greedy user thread that "
              << "never calls yield() monopolizes its carrier thread and starves all siblings.\n";
    return 0;
}
