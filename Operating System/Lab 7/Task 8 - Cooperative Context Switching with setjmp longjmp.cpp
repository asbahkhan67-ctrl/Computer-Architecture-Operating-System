#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
// Cooperative downward longjmp between sibling stack frames requires bypassing
// glibc's __longjmp_chk stack-direction check enabled by default under -O2.
#ifdef _FORTIFY_SOURCE
#undef _FORTIFY_SOURCE
#endif

// Lab 7 Task 8: Cooperative Context Switching with setjmp / longjmp (C++17)
#include <csetjmp>
#include <iostream>

using namespace std;

namespace {

jmp_buf g_ctx_a;
jmp_buf g_ctx_b;
jmp_buf g_ctx_done;
volatile int g_b_started = 0;

__attribute__((noinline)) void task_B() {
    for (volatile int step = 1; step <= 5; ++step) {
        cout << "Task B executing step: " << step << "\n";
        if (setjmp(g_ctx_b) == 0) {
            longjmp(g_ctx_a, 1);
        }
    }
    longjmp(g_ctx_done, 1);
}

__attribute__((noinline)) void launch_b_with_spacer() {
    // Keep Task B's frame 32 KB below Task A's frame so Task A never overwrites it
    volatile char frame_spacer[32768];
    frame_spacer[0] = 1;
    (void)frame_spacer[0];
    task_B();
}

__attribute__((noinline)) void task_A() {
    for (volatile int step = 1; step <= 5; ++step) {
        cout << "Task A executing step: " << step << "\n";
        if (setjmp(g_ctx_a) == 0) {
            if (!g_b_started) {
                g_b_started = 1;
                launch_b_with_spacer();
            } else {
                longjmp(g_ctx_b, 1);
            }
        }
    }
    // Let Task B finish its final step 5 if still suspended
    longjmp(g_ctx_b, 1);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 8: Cooperative Context Switching with setjmp/longjmp ===\n";
    if (setjmp(g_ctx_done) == 0) {
        task_A();
    }
    cout << "Both cooperative coroutines completed 5 steps each.\n";
    return 0;
}
