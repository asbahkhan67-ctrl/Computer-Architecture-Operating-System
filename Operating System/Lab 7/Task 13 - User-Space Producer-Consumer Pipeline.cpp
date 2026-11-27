#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 13: User-Space Producer-Consumer Pipeline (C++17)
#include <cassert>
#include <cstdlib>
#include <deque>
#include <iostream>
#include <ucontext.h>

using namespace std;

namespace {

constexpr size_t ULT_STACK_SIZE = 65536;
constexpr int BUF_CAP = 5;
constexpr int TOTAL_ITEMS = 20;

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

int g_user_buffer[BUF_CAP];
int g_user_items = 0;
int g_in = 0;
int g_out = 0;
UserMutex g_queue_lock;
int g_produced = 0;
int g_consumed = 0;
long long g_sum_produced = 0;
long long g_sum_consumed = 0;

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
        g_current_thread->state = State::BLOCKED;
        mtx->wait_queue.push_back(g_current_thread);
        swapcontext(&g_current_thread->context, &g_scheduler_context);
    }
}

void user_mutex_unlock(UserMutex* mtx) {
    assert(mtx->owner == g_current_thread);
    if (!mtx->wait_queue.empty()) {
        ULT_TCB* nxt = mtx->wait_queue.front();
        mtx->wait_queue.pop_front();
        nxt->state = State::READY;
        mtx->owner = nxt;
        g_ready_queue.push_back(nxt);
    } else {
        mtx->locked = false;
        mtx->owner = nullptr;
    }
}

void user_producer() {
    while (g_produced < TOTAL_ITEMS) {
        user_mutex_lock(&g_queue_lock);
        if (g_user_items < BUF_CAP) {
            int item = ++g_produced;
            g_user_buffer[g_in] = item;
            g_in = (g_in + 1) % BUF_CAP;
            ++g_user_items;
            g_sum_produced += item;
            cout << "[Producer ULT] Produced item " << item
                 << " | Buffer occupancy: " << g_user_items << "/" << BUF_CAP << "\n";
            user_mutex_unlock(&g_queue_lock);
            my_thread_yield();
        } else {
            user_mutex_unlock(&g_queue_lock);
            my_thread_yield();
        }
    }
    g_current_thread->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void user_consumer() {
    while (g_consumed < TOTAL_ITEMS) {
        user_mutex_lock(&g_queue_lock);
        if (g_user_items > 0) {
            int item = g_user_buffer[g_out];
            g_out = (g_out + 1) % BUF_CAP;
            --g_user_items;
            ++g_consumed;
            g_sum_consumed += item;
            cout << "[Consumer ULT] Consumed item " << item
                 << " | Buffer occupancy: " << g_user_items << "/" << BUF_CAP << "\n";
            user_mutex_unlock(&g_queue_lock);
            my_thread_yield();
        } else {
            user_mutex_unlock(&g_queue_lock);
            my_thread_yield();
        }
    }
    g_current_thread->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void spawn(int id, void (*fn)()) {
    auto* tcb = new ULT_TCB();
    tcb->id = id;
    tcb->stack = malloc(ULT_STACK_SIZE);
    getcontext(&tcb->context);
    tcb->context.uc_stack.ss_sp = tcb->stack;
    tcb->context.uc_stack.ss_size = ULT_STACK_SIZE;
    tcb->context.uc_link = &g_scheduler_context;
    makecontext(&tcb->context, fn, 0);
    g_ready_queue.push_back(tcb);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 13: User-Space Producer-Consumer Pipeline ===\n";

    spawn(1, user_producer);
    spawn(2, user_consumer);

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

    bool ok = (g_produced == TOTAL_ITEMS) && (g_consumed == TOTAL_ITEMS) &&
              (g_sum_produced == g_sum_consumed);
    cout << "\nProduced=" << g_produced << ", Consumed=" << g_consumed
         << ", Checksum=" << g_sum_consumed << " -> " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
