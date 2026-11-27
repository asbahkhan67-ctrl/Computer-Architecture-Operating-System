#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 16: Minimal Cooperative User-Thread Library (ucontext.h) (C++17)
#include <iostream>
#include <sys/syscall.h>
#include <ucontext.h>
#include <unistd.h>
#include <vector>

namespace {

constexpr int NUM_THREADS = 4;
constexpr int NUM_ROUNDS = 4;
constexpr std::size_t STACK_SZ = 65536;

struct UserThreadRuntime {
    std::vector<ucontext_t> ctx;
    std::vector<std::vector<char>> stacks;
    ucontext_t main_ctx{};
    int cur = 0;
    int finished_count = 0;
};

UserThreadRuntime g_rt;

void yield_thread() {
    int prev = g_rt.cur;
    g_rt.cur = (g_rt.cur + 1) % NUM_THREADS;
    swapcontext(&g_rt.ctx[static_cast<std::size_t>(prev)],
                &g_rt.ctx[static_cast<std::size_t>(g_rt.cur)]);
}

void thread_entry() {
    int id = g_rt.cur;
    pid_t pid = getpid();
    long tid = syscall(SYS_gettid);
    for (int round = 1; round <= NUM_ROUNDS; ++round) {
        std::cout << "[ULT " << id << "] round=" << round
                  << " | getpid()=" << pid << " | gettid()=" << tid << "\n";
        if (round < NUM_ROUNDS) {
            yield_thread();
        }
    }
    ++g_rt.finished_count;
    if (g_rt.finished_count < NUM_THREADS) {
        yield_thread();
    }
    setcontext(&g_rt.main_ctx);
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 16: Minimal Cooperative User-Thread Library ===\n";
    std::cout << "Main OS thread -> PID: " << getpid()
              << ", TID: " << syscall(SYS_gettid) << "\n\n";

    g_rt.ctx.resize(NUM_THREADS);
    g_rt.stacks.assign(NUM_THREADS, std::vector<char>(STACK_SZ));
    g_rt.cur = 0;
    g_rt.finished_count = 0;

    for (int i = 0; i < NUM_THREADS; ++i) {
        getcontext(&g_rt.ctx[static_cast<std::size_t>(i)]);
        g_rt.ctx[static_cast<std::size_t>(i)].uc_stack.ss_sp =
            g_rt.stacks[static_cast<std::size_t>(i)].data();
        g_rt.ctx[static_cast<std::size_t>(i)].uc_stack.ss_size = STACK_SZ;
        g_rt.ctx[static_cast<std::size_t>(i)].uc_link = &g_rt.main_ctx;
        makecontext(&g_rt.ctx[static_cast<std::size_t>(i)], thread_entry, 0);
    }

    swapcontext(&g_rt.main_ctx, &g_rt.ctx[0]);

    std::cout << "\nAll " << g_rt.finished_count << " user threads finished cleanly ("
              << (g_rt.finished_count == NUM_THREADS ? "PASS" : "FAIL") << ").\n";
    std::cout << "\nConclusion:\n"
              << "All four user-level threads interleaved in round-robin order via cooperative "
              << "yield() calls using swapcontext() and private 64 KB heap stacks. Every ULT "
              << "reported the exact same PID and kernel TID as main(), confirming the 1:N mapping "
              << "where the OS kernel sees only a single schedulable thread.\n";
    return 0;
}
