#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 3: Direct Low-Level Thread Creation via clone() (C++17)
#include <atomic>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <sched.h>
#include <sys/syscall.h>
#include <unistd.h>

using namespace std;

namespace {

constexpr size_t STACK_SIZE = 65536; // 64 KB

struct CloneCtx {
    atomic<int> done{0};
    long child_tid{0};
    int shared_value{42};
};

int child_execution(void* arg) {
    auto* ctx = static_cast<CloneCtx*>(arg);
    long tid = syscall(SYS_gettid);
    ctx->child_tid = tid;
    ctx->shared_value = 99;
    cout << "Inside child clone thread. PID: " << getpid()
         << " | Kernel TID: " << tid << "\n" << flush;
    ctx->done.store(1, memory_order_release);
    return 0;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 3: Direct Low-Level Thread Creation via clone() ===\n";
    cout << "Parent PID: " << getpid() << " | Parent Kernel TID: " << syscall(SYS_gettid) << "\n";

    void* child_stack = aligned_alloc(16, STACK_SIZE);
    if (!child_stack) {
        cerr << "Stack allocation failed\n";
        return 1;
    }
    char* stack_top = static_cast<char*>(child_stack) + STACK_SIZE;

    CloneCtx ctx;
    const int clone_flags = CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD;

    int tid = clone(child_execution, stack_top, clone_flags, &ctx);
    if (tid == -1) {
        cerr << "clone() failed: " << strerror(errno) << "\n";
        free(child_stack);
        return 1;
    }

    cout << "Spawned kernel thread with TID: " << tid << "\n";
    while (ctx.done.load(memory_order_acquire) == 0) {
        sched_yield();
    }
    // Brief grace delay so the child thread exits before freeing its stack
    usleep(50000);

    cout << "Observed shared_value updated via CLONE_VM: " << ctx.shared_value
         << " | Child TID match: " << (ctx.child_tid == tid ? "PASS" : "FAIL") << "\n";

    free(child_stack);
    return 0;
}
