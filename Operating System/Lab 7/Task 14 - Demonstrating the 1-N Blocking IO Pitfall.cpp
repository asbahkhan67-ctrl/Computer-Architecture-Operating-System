#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 14: Demonstrating the 1:N Blocking I/O Pitfall (C++17)
#include <atomic>
#include <chrono>
#include <cstring>
#include <iostream>
#include <pthread.h>
#include <sys/syscall.h>
#include <thread>
#include <ucontext.h>
#include <unistd.h>

using namespace std;

namespace {

constexpr size_t STK_SIZE = 65536;

ucontext_t g_main_ctx, g_ult_ctx[2];
char g_stk[2][STK_SIZE];
int g_cur = 0;
int g_ult_fd = STDIN_FILENO;
volatile bool g_ult_done = false;
volatile long long g_ult_ticks = 0;

void my_thread_yield() {
    int prev_id = g_cur;
    g_cur = 1 - g_cur;
    swapcontext(&g_ult_ctx[prev_id], &g_ult_ctx[g_cur]);
}

void ult_thread_blocking() {
    cout << "ULT 1: Waiting on blocking I/O (fd=" << g_ult_fd << ")...\n" << flush;
    char buf[100];
    ssize_t n = read(g_ult_fd, buf, sizeof(buf));
    cout << "ULT 1: Received I/O (" << n << " bytes)! ULT 2 heartbeat ticks = "
         << g_ult_ticks << "\n";
    g_ult_done = true;
    setcontext(&g_main_ctx);
}

void ult_thread_heartbeat() {
    while (!g_ult_done) {
        ++g_ult_ticks;
        cout << "ULT 2: Heartbeat tick (active) #" << g_ult_ticks << "\n";
        my_thread_yield();
    }
    setcontext(&g_main_ctx);
}

struct KltDemo {
    int fd = STDIN_FILENO;
    atomic<bool> done{false};
    atomic<long long> ticks{0};
};

void* pthread_blocking(void* arg) {
    auto* d = static_cast<KltDemo*>(arg);
    cout << "KLT 1 (TID=" << syscall(SYS_gettid) << "): Waiting on blocking I/O (fd="
         << d->fd << ")...\n" << flush;
    char buf[100];
    ssize_t n = read(d->fd, buf, sizeof(buf));
    cout << "KLT 1: Received I/O (" << n << " bytes)!\n";
    d->done.store(true);
    return nullptr;
}

void* pthread_heartbeat(void* arg) {
    auto* d = static_cast<KltDemo*>(arg);
    while (!d->done.load()) {
        long long t = d->ticks.fetch_add(1) + 1;
        if (t <= 5) {
            cout << "KLT 2 (TID=" << syscall(SYS_gettid)
                 << "): Heartbeat tick (active) #" << t << "\n";
        }
        usleep(80000);
    }
    return nullptr;
}

} // namespace

int main(int argc, char* argv[]) {
    bool demo = (argc > 1 && strcmp(argv[1], "--demo") == 0);

    cout << "=== Lab 7 Task 14: Demonstrating the 1:N Blocking I/O Pitfall ===\n";
    cout << "Mode: " << (demo ? "--demo (automated 500ms pipe delay)" : "stdin (press Enter)") << "\n\n";

    // Phase A: 1:N ULT model
    cout << "--- Phase A: 1:N User-Level Threads ---\n";
    int p_a[2]{-1, -1};
    thread wr_a;
    if (demo) {
        if (pipe(p_a) != 0) return 1;
        g_ult_fd = p_a[0];
        wr_a = thread([&]() {
            this_thread::sleep_for(chrono::milliseconds(500));
            const char msg[] = "hello\n";
            ssize_t r = write(p_a[1], msg, sizeof(msg) - 1);
            (void)r;
        });
    } else {
        g_ult_fd = STDIN_FILENO;
    }

    g_cur = 0;
    g_ult_done = false;
    g_ult_ticks = 0;
    for (int i = 0; i < 2; ++i) {
        getcontext(&g_ult_ctx[i]);
        g_ult_ctx[i].uc_stack.ss_sp = g_stk[i];
        g_ult_ctx[i].uc_stack.ss_size = STK_SIZE;
        g_ult_ctx[i].uc_link = &g_main_ctx;
        makecontext(&g_ult_ctx[i], i == 0 ? ult_thread_blocking : ult_thread_heartbeat, 0);
    }
    swapcontext(&g_main_ctx, &g_ult_ctx[0]);
    if (demo) {
        wr_a.join();
        close(p_a[0]);
        close(p_a[1]);
    }

    // Phase B: 1:1 KLT model (pthreads)
    cout << "\n--- Phase B: 1:1 Kernel-Level Threads (pthreads) ---\n";
    KltDemo kdemo;
    int p_b[2]{-1, -1};
    thread wr_b;
    if (demo) {
        if (pipe(p_b) != 0) return 1;
        kdemo.fd = p_b[0];
        wr_b = thread([&]() {
            this_thread::sleep_for(chrono::milliseconds(500));
            const char msg[] = "world\n";
            ssize_t r = write(p_b[1], msg, sizeof(msg) - 1);
            (void)r;
        });
    } else {
        kdemo.fd = STDIN_FILENO;
    }

    pthread_t k1, k2;
    pthread_create(&k1, nullptr, pthread_blocking, &kdemo);
    pthread_create(&k2, nullptr, pthread_heartbeat, &kdemo);
    pthread_join(k1, nullptr);
    pthread_join(k2, nullptr);
    if (demo) {
        wr_b.join();
        close(p_b[0]);
        close(p_b[1]);
    }

    bool ok = (g_ult_ticks == 0) && (kdemo.ticks.load() > 0);
    cout << "\nSummary: ULT 2 ticks while blocked = " << g_ult_ticks
         << " | KLT 2 ticks while blocked = " << kdemo.ticks.load()
         << " -> " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
