#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 10: Round-Robin Cooperative ULT Scheduler (C++17)
#include <cstdlib>
#include <deque>
#include <iostream>
#include <ucontext.h>

using namespace std;

namespace {

constexpr size_t ULT_STACK_SIZE = 65536;

enum class ThreadState { READY, RUNNING, TERMINATED };

struct ULT_TCB {
    int id = 0;
    ucontext_t context{};
    void* stack = nullptr;
    ThreadState state = ThreadState::READY;
    int steps = 0;
};

deque<ULT_TCB*> g_ready_queue;
ULT_TCB* g_current_thread = nullptr;
ucontext_t g_scheduler_context{};

void my_thread_yield() {
    ULT_TCB* prev_tcb = g_current_thread;
    prev_tcb->state = ThreadState::READY;
    g_ready_queue.push_back(prev_tcb);
    swapcontext(&prev_tcb->context, &g_scheduler_context);
}

void ult_worker_trampoline() {
    ULT_TCB* self = g_current_thread;
    for (int s = 1; s <= self->steps; ++s) {
        cout << "  [ULT " << self->id << "] executing step " << s << "/" << self->steps << "\n";
        if (s < self->steps) {
            my_thread_yield();
        }
    }
    self->state = ThreadState::TERMINATED;
    setcontext(&g_scheduler_context);
}

void my_thread_create(int id, int steps) {
    auto* tcb = new ULT_TCB();
    tcb->id = id;
    tcb->steps = steps;
    tcb->state = ThreadState::READY;
    tcb->stack = malloc(ULT_STACK_SIZE);

    getcontext(&tcb->context);
    tcb->context.uc_stack.ss_sp = tcb->stack;
    tcb->context.uc_stack.ss_size = ULT_STACK_SIZE;
    tcb->context.uc_link = &g_scheduler_context;
    makecontext(&tcb->context, ult_worker_trampoline, 0);

    g_ready_queue.push_back(tcb);
}

void scheduler_loop() {
    while (!g_ready_queue.empty()) {
        g_current_thread = g_ready_queue.front();
        g_ready_queue.pop_front();
        g_current_thread->state = ThreadState::RUNNING;

        swapcontext(&g_scheduler_context, &g_current_thread->context);

        if (g_current_thread->state == ThreadState::TERMINATED) {
            cout << "[Scheduler] Reaping terminated ULT " << g_current_thread->id << "\n";
            free(g_current_thread->stack);
            delete g_current_thread;
            g_current_thread = nullptr;
        }
    }
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 10: Round-Robin Cooperative ULT Scheduler ===\n";

    my_thread_create(1, 3);
    my_thread_create(2, 2);
    my_thread_create(3, 4);
    my_thread_create(4, 2);

    scheduler_loop();
    cout << "All cooperative user-level threads completed and reaped cleanly.\n";
    return 0;
}
