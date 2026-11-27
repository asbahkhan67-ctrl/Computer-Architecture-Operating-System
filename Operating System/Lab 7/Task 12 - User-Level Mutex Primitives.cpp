#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 12: User-Level Mutex Primitives (Cooperative Locks) (C++17)
#include <cassert>
#include <cstdlib>
#include <deque>
#include <iostream>
#include <ucontext.h>

using namespace std;

namespace {

constexpr size_t ULT_STACK_SIZE = 65536;

enum class State { READY, RUNNING, BLOCKED, TERMINATED };

struct ULT_TCB {
    int id = 0;
    ucontext_t context{};
    void* stack = nullptr;
    State state = State::READY;
};

struct UserMutex {
    bool locked = false;
    ULT_TCB* owner = nullptr;
    deque<ULT_TCB*> wait_queue;
};

deque<ULT_TCB*> g_ready_queue;
ULT_TCB* g_current_thread = nullptr;
ucontext_t g_scheduler_context{};
UserMutex g_mutex;
int g_shared_counter = 0;

void my_thread_yield() {
    ULT_TCB* prev_tcb = g_current_thread;
    prev_tcb->state = State::READY;
    g_ready_queue.push_back(prev_tcb);
    swapcontext(&prev_tcb->context, &g_scheduler_context);
}

void user_mutex_lock(UserMutex* mtx) {
    if (!mtx->locked) {
        mtx->locked = true;
        mtx->owner = g_current_thread;
    } else {
        cout << "  [ULT " << g_current_thread->id << "] contended -> BLOCKED on UserMutex\n";
        g_current_thread->state = State::BLOCKED;
        mtx->wait_queue.push_back(g_current_thread);
        swapcontext(&g_current_thread->context, &g_scheduler_context);
    }
}

void user_mutex_unlock(UserMutex* mtx) {
    assert(mtx->owner == g_current_thread);
    if (!mtx->wait_queue.empty()) {
        ULT_TCB* next_tcb = mtx->wait_queue.front();
        mtx->wait_queue.pop_front();
        next_tcb->state = State::READY;
        mtx->owner = next_tcb;
        g_ready_queue.push_back(next_tcb);
        cout << "  [ULT " << g_current_thread->id << "] unlocked -> woke ULT "
             << next_tcb->id << "\n";
    } else {
        mtx->locked = false;
        mtx->owner = nullptr;
    }
}

void mutex_worker() {
    ULT_TCB* self = g_current_thread;
    for (int iter = 1; iter <= 3; ++iter) {
        user_mutex_lock(&g_mutex);
        int before = g_shared_counter;
        // Yield while holding the UserMutex to force contention on siblings
        my_thread_yield();
        g_shared_counter = before + 1;
        cout << "  [ULT " << self->id << "] critical section iter " << iter
             << " -> counter=" << g_shared_counter << "\n";
        user_mutex_unlock(&g_mutex);
        my_thread_yield();
    }
    self->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void create_ult(int id) {
    auto* tcb = new ULT_TCB();
    tcb->id = id;
    tcb->stack = malloc(ULT_STACK_SIZE);
    getcontext(&tcb->context);
    tcb->context.uc_stack.ss_sp = tcb->stack;
    tcb->context.uc_stack.ss_size = ULT_STACK_SIZE;
    tcb->context.uc_link = &g_scheduler_context;
    makecontext(&tcb->context, mutex_worker, 0);
    g_ready_queue.push_back(tcb);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 12: User-Level Mutex Primitives (Cooperative Locks) ===\n";

    for (int id = 1; id <= 4; ++id) {
        create_ult(id);
    }

    while (!g_ready_queue.empty()) {
        g_current_thread = g_ready_queue.front();
        g_ready_queue.pop_front();
        g_current_thread->state = State::RUNNING;
        swapcontext(&g_scheduler_context, &g_current_thread->context);

        if (g_current_thread->state == State::TERMINATED) {
            free(g_current_thread->stack);
            delete g_current_thread;
            g_current_thread = nullptr;
        }
    }

    cout << "\nFinal g_shared_counter = " << g_shared_counter
         << " (expected 12): " << (g_shared_counter == 12 ? "PASS" : "FAIL") << "\n";
    return 0;
}
