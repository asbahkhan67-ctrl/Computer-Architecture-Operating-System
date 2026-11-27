#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 19: Visualising Kernel Threads via /proc (C++17)
#include <algorithm>
#include <cstdlib>
#include <dirent.h>
#include <iostream>
#include <pthread.h>
#include <string>
#include <sys/syscall.h>
#include <unistd.h>
#include <vector>

namespace {

struct WorkerInfo {
    int id;
    int sleep_secs;
    long tid;
};

pthread_mutex_t g_print_mtx = PTHREAD_MUTEX_INITIALIZER;

void* worker_fn(void* arg) {
    auto* info = static_cast<WorkerInfo*>(arg);
    info->tid = syscall(SYS_gettid);
    pthread_mutex_lock(&g_print_mtx);
    std::cout << "[Worker " << info->id << "] getpid() = " << getpid()
              << " | gettid() = " << info->tid << " (sleeping " << info->sleep_secs << "s)\n";
    pthread_mutex_unlock(&g_print_mtx);
    sleep(static_cast<unsigned int>(info->sleep_secs));
    return nullptr;
}

std::vector<std::string> list_proc_tasks(pid_t pid) {
    std::vector<std::string> tids;
    std::string path = "/proc/" + std::to_string(pid) + "/task";
    DIR* dir = opendir(path.c_str());
    if (!dir) return tids;
    while (struct dirent* ent = readdir(dir)) {
        std::string name = ent->d_name;
        if (name != "." && name != "..") {
            tids.push_back(name);
        }
    }
    closedir(dir);
    std::sort(tids.begin(), tids.end());
    return tids;
}

} // namespace

int main(int argc, char* argv[]) {
    int sleep_secs = 30;
    if (argc > 1) {
        int v = std::atoi(argv[1]);
        if (v >= 1) sleep_secs = v;
    }

    pid_t pid = getpid();
    long main_tid = syscall(SYS_gettid);
    std::cout << "=== Lab 6 Task 19: Visualising Kernel Threads via /proc ===\n";
    std::cout << "Main thread -> getpid() = " << pid << " | gettid() = " << main_tid << "\n";
    std::cout << "Shell inspection commands:\n"
              << "  ps -L -p " << pid << "\n"
              << "  ls /proc/" << pid << "/task\n\n";

    constexpr int NUM_WORKERS = 4;
    pthread_t threads[NUM_WORKERS];
    WorkerInfo infos[NUM_WORKERS];

    for (int i = 0; i < NUM_WORKERS; ++i) {
        infos[i] = {i + 1, sleep_secs, 0};
        pthread_create(&threads[i], nullptr, worker_fn, &infos[i]);
    }

    usleep(100000); // Allow workers to register in /proc/<pid>/task
    auto proc_tids = list_proc_tasks(pid);
    std::cout << "\nEntries in /proc/" << pid << "/task (" << proc_tids.size() << " total):";
    for (const auto& t : proc_tids) {
        std::cout << " " << t;
    }
    std::cout << "\n" << std::flush;

    for (int i = 0; i < NUM_WORKERS; ++i) {
        pthread_join(threads[i], nullptr);
    }

    bool ok = (proc_tids.size() == 5);
    std::cout << "\nExpected 5 kernel tasks (1 main + 4 workers), observed "
              << proc_tids.size() << ": " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "All four pthreads share the same process ID (PID) while receiving distinct "
              << "kernel thread IDs (TIDs) from SYS_gettid. Inspecting /proc/<pid>/task reveals "
              << "five entries—the main thread plus the four workers—confirming Linux's 1:1 "
              << "model where every pthread corresponds to an independent kernel task_struct.\n";
    return 0;
}
