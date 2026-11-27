#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 15: Non-Blocking User-Space I/O with Event Polling (epoll) (C++17)
#include <cerrno>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fcntl.h>
#include <iostream>
#include <sys/epoll.h>
#include <thread>
#include <ucontext.h>
#include <unistd.h>
#include <unordered_map>

using namespace std;

namespace {

constexpr size_t STK_SIZE = 65536;

enum class State { READY, RUNNING, WAITING_IO, TERMINATED };

struct ULT_TCB {
    int id = 0;
    ucontext_t context{};
    void* stack = nullptr;
    State state = State::READY;
    int read_fd = -1;
};

int g_epoll_fd = -1;
deque<ULT_TCB*> g_ready_queue;
unordered_map<int, ULT_TCB*> g_io_waiters;
ULT_TCB* g_current_thread = nullptr;
ucontext_t g_scheduler_context{};
volatile bool g_readers_done = false;
int g_heartbeat_ticks = 0;
int g_messages_read = 0;

void set_nonblocking_flag(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

void my_thread_yield() {
    ULT_TCB* prev_tcb = g_current_thread;
    prev_tcb->state = State::READY;
    g_ready_queue.push_back(prev_tcb);
    swapcontext(&prev_tcb->context, &g_scheduler_context);
}

ssize_t async_user_read(int fd, void* buffer, size_t length) {
    set_nonblocking_flag(fd);
    while (true) {
        ssize_t bytes = read(fd, buffer, length);
        if (bytes >= 0) return bytes;
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            epoll_event ev{};
            ev.events = EPOLLIN;
            ev.data.fd = fd;
            epoll_ctl(g_epoll_fd, EPOLL_CTL_ADD, fd, &ev);
            g_io_waiters[fd] = g_current_thread;
            g_current_thread->state = State::WAITING_IO;
            swapcontext(&g_current_thread->context, &g_scheduler_context);
            epoll_ctl(g_epoll_fd, EPOLL_CTL_DEL, fd, nullptr);
            g_io_waiters.erase(fd);
            continue;
        }
        return -1;
    }
}

void io_reader_ult() {
    ULT_TCB* self = g_current_thread;
    char buf[128]{};
    cout << "[ULT " << self->id << "] Issuing async_user_read(fd=" << self->read_fd << ")\n";
    ssize_t n = async_user_read(self->read_fd, buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';
        cout << "[ULT " << self->id << "] Resumed via epoll! Read " << n
             << " bytes: \"" << buf << "\"\n";
        ++g_messages_read;
    }
    self->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void compute_heartbeat_ult() {
    while (g_messages_read < 2) {
        ++g_heartbeat_ticks;
        if (g_heartbeat_ticks <= 5 || g_heartbeat_ticks % 20 == 0) {
            cout << "[ULT 3 Heartbeat] Still active while I/O ULTs wait! tick="
                 << g_heartbeat_ticks << "\n";
        }
        usleep(15000);
        my_thread_yield();
    }
    g_current_thread->state = State::TERMINATED;
    setcontext(&g_scheduler_context);
}

void spawn_ult(int id, void (*fn)(), int fd = -1) {
    auto* tcb = new ULT_TCB();
    tcb->id = id;
    tcb->read_fd = fd;
    tcb->stack = malloc(STK_SIZE);
    getcontext(&tcb->context);
    tcb->context.uc_stack.ss_sp = tcb->stack;
    tcb->context.uc_stack.ss_size = STK_SIZE;
    tcb->context.uc_link = &g_scheduler_context;
    makecontext(&tcb->context, fn, 0);
    g_ready_queue.push_back(tcb);
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 15: Non-Blocking User-Space I/O with epoll ===\n";

    g_epoll_fd = epoll_create1(0);
    if (g_epoll_fd < 0) return 1;

    int p1[2], p2[2];
    if (pipe(p1) != 0 || pipe(p2) != 0) return 1;

    thread feeder([&]() {
        this_thread::sleep_for(chrono::milliseconds(100));
        const char m1[] = "Pipe-1 Payload";
        ssize_t r1 = write(p1[1], m1, sizeof(m1) - 1);
        (void)r1;
        this_thread::sleep_for(chrono::milliseconds(120));
        const char m2[] = "Pipe-2 Payload";
        ssize_t r2 = write(p2[1], m2, sizeof(m2) - 1);
        (void)r2;
    });

    spawn_ult(1, io_reader_ult, p1[0]);
    spawn_ult(2, io_reader_ult, p2[0]);
    spawn_ult(3, compute_heartbeat_ult);

    epoll_event events[8];
    while (!g_ready_queue.empty() || !g_io_waiters.empty()) {
        if (!g_io_waiters.empty()) {
            int timeout_ms = g_ready_queue.empty() ? 10 : 0;
            int nev = epoll_wait(g_epoll_fd, events, 8, timeout_ms);
            for (int i = 0; i < nev; ++i) {
                int ready_fd = events[i].data.fd;
                auto it = g_io_waiters.find(ready_fd);
                if (it != g_io_waiters.end() && it->second->state == State::WAITING_IO) {
                    it->second->state = State::READY;
                    g_ready_queue.push_back(it->second);
                }
            }
        }

        if (!g_ready_queue.empty()) {
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
    }

    feeder.join();
    close(p1[0]);
    close(p1[1]);
    close(p2[0]);
    close(p2[1]);
    close(g_epoll_fd);

    bool ok = (g_messages_read == 2) && (g_heartbeat_ticks > 0);
    cout << "\nMessages read = " << g_messages_read
         << " | Heartbeat ticks during async I/O = " << g_heartbeat_ticks
         << " -> " << (ok ? "PASS" : "FAIL") << "\n";
    return 0;
}
