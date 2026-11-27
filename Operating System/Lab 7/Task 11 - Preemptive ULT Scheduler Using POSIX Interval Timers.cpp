#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 11: Preemptive ULT Scheduler Using POSIX Interval Timers (C++17)
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <iostream>
#include <sys/time.h>
#include <ucontext.h>
#include <unistd.h>

using namespace std;

namespace {

constexpr size_t ULT_STACK_SIZE = 65536;
constexpr int NUM_ULTS = 3;
constexpr long TARGET_WORK_ITERS = 60000000L;

enum class State { READY, RUNNING, TERMINATED };

struct ULT_TCB {
    int id = 0;
    ucontext_t context{};
    void* stack = nullptr;
    State state = State::READY;
    long progress = 0;
    int preemptions = 0;
};

deque<ULT_TCB*> g_ready_queue;
ULT_TCB* g_current_thread = nullptr;
ucontext_t g_scheduler_context{};
sigset_t g_vt_mask;
volatile sig_atomic_t g_tick_count = 0;

void block_timer() { sigprocmask(SIG_BLOCK, &g_vt_mask, nullptr); }
void unblock_timer() { sigprocmask(SIG_UNBLOCK, &g_vt_mask, nullptr); }

void my_thread_yield() {
    block_timer();
    ULT_TCB* prev_tcb = g_current_thread;
    if (prev_tcb && prev_tcb->state == State::RUNNING) {
        prev_tcb->state = State::READY;
        g_ready_queue.push_back(prev_tcb);
        swapcontext(&prev_tcb->context, &g_scheduler_context);
    }
    unblock_timer();
}

void timer_signal_handler(int) {
    ++g_tick_count;
    const char msg[] = "Timer tick expired: Preempting running ULT\n";
    ssize_t r = write(STDOUT_FILENO, msg, sizeof(msg) - 1);
    (void)r;

    if (g_current_thread && g_current_thread->state == State::RUNNING) {
        ++g_current_thread->preemptions;
        my_thread_yield();
    }
}

void init_preemption() {
    sigemptyset(&g_vt_mask);
    sigaddset(&g_vt_mask, SIGVTALRM);

    struct sigaction sa {};
    sa.sa_handler = timer_signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    sigaction(SIGVTALRM, &sa, nullptr);

    struct itimerval timer_conf {};
    timer_conf.it_interval.tv_sec = 0;
    timer_conf.it_interval.tv_usec = 20000; // 20 ms
    timer_conf.it_value.tv_sec = 0;
    timer_conf.it_value.tv_usec = 20000;
    setitimer(ITIMER_VIRTUAL, &timer_conf, nullptr);
}

void stop_preemption() {
    struct itimerval off {};
    setitimer(ITIMER_VIRTUAL, &off, nullptr);
    block_timer();
}

void compute_worker() {
    unblock_timer();
    ULT_TCB* self = g_current_thread;
    volatile long sink = 0;
    // No explicit my_thread_yield() calls: only SIGVTALRM preempts this loop
    for (long i = 0; i < TARGET_WORK_ITERS; ++i) {
        sink = sink + (i & 7);
        self->progress = i + 1;
    }
    block_timer();
    self->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void spawn_ult(int id) {
    auto* tcb = new ULT_TCB();
    tcb->id = id;
    tcb->state = State::READY;
    tcb->stack = malloc(ULT_STACK_SIZE);
    getcontext(&tcb->context);
    sigdelset(&tcb->context.uc_sigmask, SIGVTALRM);
    tcb->context.uc_stack.ss_sp = tcb->stack;
    tcb->context.uc_stack.ss_size = ULT_STACK_SIZE;
    tcb->context.uc_link = &g_scheduler_context;
    makecontext(&tcb->context, compute_worker, 0);
    g_ready_queue.push_back(tcb);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 11: Preemptive ULT Scheduler (SIGVTALRM 20ms) ===\n";

    sigemptyset(&g_vt_mask);
    sigaddset(&g_vt_mask, SIGVTALRM);

    for (int i = 1; i <= NUM_ULTS; ++i) {
        spawn_ult(i);
    }

    init_preemption();
    block_timer();

    int total_preemptions = 0;
    int completed = 0;
    while (!g_ready_queue.empty()) {
        g_current_thread = g_ready_queue.front();
        g_ready_queue.pop_front();
        g_current_thread->state = State::RUNNING;

        swapcontext(&g_scheduler_context, &g_current_thread->context);

        if (g_current_thread->state == State::TERMINATED) {
            cout << "[Scheduler] ULT " << g_current_thread->id
                 << " completed " << g_current_thread->progress
                 << " iters (preempted " << g_current_thread->preemptions << " times)\n";
            total_preemptions += g_current_thread->preemptions;
            ++completed;
            free(g_current_thread->stack);
            delete g_current_thread;
            g_current_thread = nullptr;
        }
    }

    stop_preemption();
    cout << "Total SIGVTALRM ticks: " << g_tick_count
         << " | Total preemptions: " << total_preemptions
         << " | Completed: " << completed << "/" << NUM_ULTS << "\n";
    return 0;
}
