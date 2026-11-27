#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 20: Asynchronous Signal Routing in ULT vs. KLT (C++17)
#include <atomic>
#include <csignal>
#include <cstring>
#include <iostream>
#include <pthread.h>
#include <sys/syscall.h>
#include <ucontext.h>
#include <unistd.h>

using namespace std;

namespace {

// --- Part A: KLT Directed Signal Routing via pthread_sigmask + sigwait ---
atomic<int> g_signals_handled{0};
atomic<bool> g_worker_done{false};
volatile int g_worker_interrupted = 0;

void* dedicated_signal_handler_thread(void*) {
    sigset_t monitored;
    sigemptyset(&monitored);
    sigaddset(&monitored, SIGINT);
    sigaddset(&monitored, SIGTERM);

    cout << "[Signal KLT TID=" << syscall(SYS_gettid)
         << "] Waiting synchronously in sigwait()...\n" << flush;

    for (int i = 0; i < 2; ++i) {
        int sig = 0;
        sigwait(&monitored, &sig);
        cout << "[Signal KLT] Signal received cleanly by designated KLT: "
             << sig << " (" << strsignal(sig) << ")\n" << flush;
        g_signals_handled.fetch_add(1);
    }
    return nullptr;
}

void* regular_worker_routine(void*) {
    cout << "[Worker KLT TID=" << syscall(SYS_gettid)
         << "] Running compute work with SIGINT/SIGTERM masked...\n" << flush;
    for (int step = 1; step <= 4; ++step) {
        usleep(40000);
    }
    g_worker_done.store(true);
    cout << "[Worker KLT] Finished uninterrupted!\n";
    return nullptr;
}

// --- Part B: ULT Process-Wide Signal Interruption ---
constexpr size_t STK_SIZE = 32768;
ucontext_t g_u_main, g_u_ctx[2];
char g_u_stk[2][STK_SIZE];
int g_u_cur = 0;
volatile sig_atomic_t g_ult_sigusr1_hits = 0;
volatile sig_atomic_t g_last_interrupted_ult = -1;

void ult_sigusr1_handler(int) {
    ++g_ult_sigusr1_hits;
    g_last_interrupted_ult = g_u_cur;
    const char msg[] = "[Process Signal Handler] SIGUSR1 interrupted active ULT!\n";
    ssize_t r = write(STDOUT_FILENO, msg, sizeof(msg) - 1);
    (void)r;
}

void ult_fiber_fn() {
    int id = g_u_cur;
    for (int r = 1; r <= 3; ++r) {
        cout << "  [ULT " << id << "] step " << r << "\n";
        if (id == 1 && r == 2) {
            kill(getpid(), SIGUSR1); // Arrives at process level on active fiber
        }
        g_u_cur = 1 - g_u_cur;
        swapcontext(&g_u_ctx[id], &g_u_ctx[g_u_cur]);
    }
    setcontext(&g_u_main);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 20: Asynchronous Signal Routing in ULT vs. KLT ===\n\n";

    // Part A: KLT masked signal routing
    cout << "--- Part A: 1:1 KLT Directed Signal Handling ---\n";
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGTERM);
    pthread_sigmask(SIG_BLOCK, &mask, nullptr);

    pthread_t sig_thread, worker_thread;
    pthread_create(&sig_thread, nullptr, dedicated_signal_handler_thread, nullptr);
    pthread_create(&worker_thread, nullptr, regular_worker_routine, nullptr);

    usleep(50000);
    kill(getpid(), SIGINT);
    usleep(30000);
    kill(getpid(), SIGTERM);

    pthread_join(sig_thread, nullptr);
    pthread_join(worker_thread, nullptr);

    // Part B: ULT process-wide signal interruption
    cout << "\n--- Part B: 1:N ULT Process-Wide Signal Interruption ---\n";
    struct sigaction sa {};
    sa.sa_handler = ult_sigusr1_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGUSR1, &sa, nullptr);

    for (int i = 0; i < 2; ++i) {
        getcontext(&g_u_ctx[i]);
        g_u_ctx[i].uc_stack.ss_sp = g_u_stk[i];
        g_u_ctx[i].uc_stack.ss_size = STK_SIZE;
        g_u_ctx[i].uc_link = &g_u_main;
        makecontext(&g_u_ctx[i], ult_fiber_fn, 0);
    }
    g_u_cur = 0;
    swapcontext(&g_u_main, &g_u_ctx[0]);

    bool ok = (g_signals_handled.load() == 2) && g_worker_done.load() &&
              (g_ult_sigusr1_hits == 1) && (g_last_interrupted_ult == 1);
    cout << "\nVerification: KLT sigwait handled=" << g_signals_handled.load()
         << "/2 | ULT interrupted fiber=" << g_last_interrupted_ult
         << " -> " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
