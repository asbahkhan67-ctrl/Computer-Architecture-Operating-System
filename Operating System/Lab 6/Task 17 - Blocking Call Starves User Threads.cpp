#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 17: Blocking Call Starves User Threads, Not Kernel Threads (C++17)
#include <atomic>
#include <chrono>
#include <cstring>
#include <iostream>
#include <pthread.h>
#include <sys/syscall.h>
#include <thread>
#include <ucontext.h>
#include <unistd.h>
#include <vector>

namespace {

constexpr std::size_t STACK_SZ = 65536;

// --- Part (a): Cooperative User-Level Threads ---
struct UltState {
    ucontext_t main_ctx{};
    ucontext_t ctx[2]{};
    std::vector<char> stk[2];
    int cur = 0;
    int read_fd = STDIN_FILENO;
    volatile long long b_counter = 0;
    volatile bool a_done = false;
    volatile long long b_ticks_during_block = 0;
};

UltState g_ult;

void ult_yield() {
    int prev = g_ult.cur;
    g_ult.cur = 1 - g_ult.cur;
    swapcontext(&g_ult.ctx[prev], &g_ult.ctx[g_ult.cur]);
}

void ult_thread_a() {
    std::cout << "[ULT A] Calling blocking read() on fd " << g_ult.read_fd << "...\n" << std::flush;
    char buf[16];
    ssize_t n = read(g_ult.read_fd, buf, 1);
    std::cout << "[ULT A] read() returned " << n << " byte(s). ULT B counter = "
              << g_ult.b_counter << "\n";
    g_ult.a_done = true;
    setcontext(&g_ult.main_ctx);
}

void ult_thread_b() {
    while (!g_ult.a_done) {
        ++g_ult.b_counter;
        if (g_ult.b_counter % 100000 == 0) {
            std::cout << "[ULT B] counter = " << g_ult.b_counter << "\n";
        }
        ult_yield();
    }
    setcontext(&g_ult.main_ctx);
}

// --- Part (b): Kernel-Level Threads (pthreads) ---
struct KltState {
    int read_fd = STDIN_FILENO;
    std::atomic<bool> a_done{false};
    std::atomic<long long> counter{0};
};

void* klt_thread_a(void* arg) {
    auto* st = static_cast<KltState*>(arg);
    std::cout << "[KLT A] Calling blocking read() on fd " << st->read_fd
              << " (TID=" << syscall(SYS_gettid) << ")...\n" << std::flush;
    char buf[16];
    ssize_t n = read(st->read_fd, buf, 1);
    std::cout << "[KLT A] read() returned " << n << " byte(s).\n";
    st->a_done.store(true);
    return nullptr;
}

void* klt_thread_b(void* arg) {
    auto* st = static_cast<KltState*>(arg);
    long long printed = 0;
    while (!st->a_done.load()) {
        long long c = st->counter.fetch_add(1) + 1;
        if (c % 2000000 == 0 && printed < 5) {
            std::cout << "[KLT B] (TID=" << syscall(SYS_gettid)
                      << ") still running! counter = " << c << "\n";
            ++printed;
        }
    }
    return nullptr;
}

} // namespace

int main(int argc, char* argv[]) {
    bool demo_mode = (argc > 1 && std::strcmp(argv[1], "--demo") == 0);

    std::cout << "=== Lab 6 Task 17: Blocking Call Starves User Threads, Not Kernel Threads ===\n";
    if (!demo_mode) {
        std::cout << "(Interactive stdin mode: press ENTER twice when prompted, or pass --demo)\n\n";
    } else {
        std::cout << "(Automated --demo mode: pipe writer sends 1 byte after 500 ms per phase)\n\n";
    }

    // --- Part (a): User-level threads ---
    std::cout << "--- Part (a): User-Level Threads ---\n";
    int pipe_a[2]{-1, -1};
    std::thread writer_a;
    if (demo_mode) {
        if (pipe(pipe_a) != 0) return 1;
        g_ult.read_fd = pipe_a[0];
        writer_a = std::thread([&]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            const char c = 'x';
            ssize_t r = write(pipe_a[1], &c, 1);
            (void)r;
        });
    } else {
        g_ult.read_fd = STDIN_FILENO;
    }

    g_ult.stk[0].assign(STACK_SZ, 0);
    g_ult.stk[1].assign(STACK_SZ, 0);
    g_ult.cur = 0;
    g_ult.b_counter = 0;
    g_ult.a_done = false;

    getcontext(&g_ult.ctx[0]);
    g_ult.ctx[0].uc_stack.ss_sp = g_ult.stk[0].data();
    g_ult.ctx[0].uc_stack.ss_size = STACK_SZ;
    g_ult.ctx[0].uc_link = &g_ult.main_ctx;
    makecontext(&g_ult.ctx[0], ult_thread_a, 0);

    getcontext(&g_ult.ctx[1]);
    g_ult.ctx[1].uc_stack.ss_sp = g_ult.stk[1].data();
    g_ult.ctx[1].uc_stack.ss_size = STACK_SZ;
    g_ult.ctx[1].uc_link = &g_ult.main_ctx;
    makecontext(&g_ult.ctx[1], ult_thread_b, 0);

    swapcontext(&g_ult.main_ctx, &g_ult.ctx[0]);
    if (demo_mode) {
        writer_a.join();
        close(pipe_a[0]);
        close(pipe_a[1]);
    }
    std::cout << "Observed ULT B ticks while ULT A blocked: " << g_ult.b_counter << " (starved)\n\n";

    // --- Part (b): Kernel-level threads (pthreads) ---
    std::cout << "--- Part (b): Kernel-Level Threads (pthreads) ---\n";
    KltState kst;
    int pipe_b[2]{-1, -1};
    std::thread writer_b;
    if (demo_mode) {
        if (pipe(pipe_b) != 0) return 1;
        kst.read_fd = pipe_b[0];
        writer_b = std::thread([&]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            const char c = 'y';
            ssize_t r = write(pipe_b[1], &c, 1);
            (void)r;
        });
    } else {
        kst.read_fd = STDIN_FILENO;
    }

    pthread_t pa, pb;
    pthread_create(&pa, nullptr, klt_thread_a, &kst);
    pthread_create(&pb, nullptr, klt_thread_b, &kst);
    pthread_join(pa, nullptr);
    pthread_join(pb, nullptr);

    if (demo_mode) {
        writer_b.join();
        close(pipe_b[0]);
        close(pipe_b[1]);
    }

    long long klt_count = kst.counter.load();
    std::cout << "Observed KLT B ticks while KLT A blocked: " << klt_count << "\n";
    bool ok = (g_ult.b_counter == 0) && (klt_count > 0);
    std::cout << "Comparison check: " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "In the 1:N user-level thread version, Thread A's blocking read() syscall suspends "
              << "the single underlying OS thread in the kernel, so Thread B gets 0 ticks until I/O "
              << "completes. With 1:1 pthreads, the kernel puts only Thread A to sleep on the wait "
              << "queue while keeping Thread B scheduled on a CPU core. Handling blocking I/O without "
              << "starving siblings therefore requires either kernel threads or non-blocking async I/O.\n";
    return 0;
}
