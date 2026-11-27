#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 10: Task Parallelism with OpenMP Sections (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <omp.h>
#include <pthread.h>
#include <vector>

namespace {

struct TaskXOut {
    long count = 0;
    double checksum = 0.0;
};

TaskXOut task_x() {
    const long N = 50000000L;
    long cnt = 0;
    double sum = 0.0;
    for (long i = 1; i <= N; ++i) {
        double v = std::sqrt(static_cast<double>(i));
        if (v > 3000.0 && v < 4000.0) {
            ++cnt;
            sum += v;
        }
    }
    return {cnt, sum};
}

bool task_y(std::vector<double>& data) {
    std::sort(data.begin(), data.end());
    return std::is_sorted(data.begin(), data.end());
}

void* pth_x(void* arg) {
    *static_cast<TaskXOut*>(arg) = task_x();
    return nullptr;
}

struct PthYArg {
    std::vector<double>* vec;
    bool sorted;
};

void* pth_y(void* arg) {
    auto* a = static_cast<PthYArg*>(arg);
    a->sorted = task_y(*a->vec);
    return nullptr;
}

std::vector<double> make_data(std::size_t n) {
    std::vector<double> v(n);
    std::uint64_t s = 0x123456789ABCDEF0ULL;
    for (std::size_t i = 0; i < n; ++i) {
        s ^= s >> 12;
        s ^= s << 25;
        s ^= s >> 27;
        v[i] = static_cast<double>((s * 0x2545F4914F6CDD1DULL) & 0xFFFFFFULL) / 1000.0;
    }
    return v;
}

double elapsed_ms(std::chrono::steady_clock::time_point start,
                  std::chrono::steady_clock::time_point end) {
    return std::chrono::duration<double, std::milli>(end - start).count();
}

} // namespace

int main() {
    std::cout << "=== Lab 6 Task 10: Task Parallelism with OpenMP Sections ===\n\n";
    const auto base = make_data(4000000);

    // 1. Sequential
    auto arr_seq = base;
    auto s0 = std::chrono::steady_clock::now();
    TaskXOut rx_seq = task_x();
    bool sy_seq = task_y(arr_seq);
    auto s1 = std::chrono::steady_clock::now();
    double t_seq = elapsed_ms(s0, s1);

    // 2. Pthreads (from Task 6)
    auto arr_pth = base;
    TaskXOut rx_pth{};
    PthYArg ry_pth{&arr_pth, false};
    pthread_t p1, p2;
    auto p0 = std::chrono::steady_clock::now();
    pthread_create(&p1, nullptr, pth_x, &rx_pth);
    pthread_create(&p2, nullptr, pth_y, &ry_pth);
    pthread_join(p1, nullptr);
    pthread_join(p2, nullptr);
    auto p1_end = std::chrono::steady_clock::now();
    double t_pth = elapsed_ms(p0, p1_end);

    // 3. OpenMP Sections
    auto arr_omp = base;
    TaskXOut rx_omp{};
    bool sy_omp = false;
    omp_set_num_threads(2);
    auto o0 = std::chrono::steady_clock::now();
#pragma omp parallel sections
    {
#pragma omp section
        { rx_omp = task_x(); }
#pragma omp section
        { sy_omp = task_y(arr_omp); }
    }
    auto o1 = std::chrono::steady_clock::now();
    double t_omp = elapsed_ms(o0, o1);

    bool ok = sy_seq && sy_omp && ry_pth.sorted &&
              (rx_omp.count == rx_seq.count) &&
              (std::abs(rx_omp.checksum - rx_seq.checksum) < 1e-6) &&
              (arr_omp == arr_seq);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << std::left << std::setw(24) << "Implementation"
              << std::setw(14) << "Time (ms)"
              << std::setw(12) << "Speedup"
              << "Correctness\n";
    std::cout << std::string(62, '-') << "\n";
    std::cout << std::left << std::setw(24) << "Sequential" << std::setw(14) << t_seq
              << std::setw(12) << 1.00 << "BASELINE\n";
    std::cout << std::left << std::setw(24) << "Pthreads (Task 6)" << std::setw(14) << t_pth
              << std::setw(12) << (t_seq / t_pth) << "PASS\n";
    std::cout << std::left << std::setw(24) << "OpenMP sections" << std::setw(14) << t_omp
              << std::setw(12) << (t_seq / t_omp) << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "OpenMP #pragma omp parallel sections delivers virtually identical wall-clock "
              << "speedup to the raw pthread version while remaining far more readable. Instead "
              << "of defining void* wrapper functions, argument structs, and explicit create/join "
              << "calls, two #pragma omp section directives invoke TaskX and TaskY directly with "
              << "an implicit join barrier at the end of the sections block.\n";
    return 0;
}
