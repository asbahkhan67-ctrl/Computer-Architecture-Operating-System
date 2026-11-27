#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 9: Fiber Creation and Stack Allocation with ucontext.h (C++17)
#include <cstdlib>
#include <iostream>
#include <ucontext.h>

using namespace std;

namespace {

// 64 KB stack gives ample headroom for C++ std::cout internals on x86-64 glibc (16 KB minimum)
constexpr size_t FIBER_STACK_SIZE = 65536;

ucontext_t g_ctx_main, g_ctx_worker;

void fiber_entry() {
    cout << "Inside fiber function execution.\n";
    cout << "Switching back to main program via uc_link...\n";
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 9: Fiber Creation and Stack Allocation with ucontext.h ===\n";

    getcontext(&g_ctx_worker);
    void* fiber_stack = malloc(FIBER_STACK_SIZE);
    if (!fiber_stack) return 1;

    g_ctx_worker.uc_stack.ss_sp = fiber_stack;
    g_ctx_worker.uc_stack.ss_size = FIBER_STACK_SIZE;
    g_ctx_worker.uc_link = &g_ctx_main;

    makecontext(&g_ctx_worker, fiber_entry, 0);

    cout << "Yielding execution to fiber...\n";
    swapcontext(&g_ctx_main, &g_ctx_worker);
    cout << "Returned cleanly to main process.\n";

    free(fiber_stack);
    return 0;
}
