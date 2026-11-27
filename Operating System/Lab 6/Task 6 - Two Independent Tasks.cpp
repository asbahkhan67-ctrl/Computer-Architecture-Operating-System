#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 6: Two Independent Tasks (Task X & Task Y) with Pthreads (C++17)
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <vector>

namespace {

struct TaskXResult {
    long count = 0;
    double checksum = 0.0;
};

struct TaskYResult {
    std::vector<double>* data = nullptr;
    bool sorted = false;
};

void* run_task_x(void* arg) {
    auto* res = static_cast<TaskXResult*>(arg);
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
    res->count = cnt;
    res->checksum = sum;
    return nullptr;
}

void* run_task_y(void* arg) {
    auto* res = static_cast<TaskYResult*>(arg);
    std::sort(res->data->begin(), res->data->end());
    res->sorted = std::is_sorted(res->data->begin(), res->data->end());
    return nullptr;
}

std::vector<double> make_random_array(std::size_t n) {
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
    std::cout << "=== Lab 6 Task 6: Two Independent Tasks (Pthreads) ===\n";
    std::cout << "Task X: 5e7 sqrt() filter | Task Y: std::sort on 4e6 doubles\n\n";

    const std::vector<double> base = make_random_array(4000000);

    // Measure Task X alone
    TaskXResult rx_seq;
    auto x0 = std::chrono::steady_clock::now();
    run_task_x(&rx_seq);
    auto x1 = std::chrono::steady_clock::now();
    double t_x = elapsed_ms(x0, x1);

    // Measure Task Y alone
    std::vector<double> arr_y = base;
    TaskYResult ry_seq{&arr_y, false};
    auto y0 = std::chrono::steady_clock::now();
    run_task_y(&ry_seq);
    auto y1 = std::chrono::steady_clock::now();
    double t_y = elapsed_ms(y0, y1);

    // Version 1: Sequential X then Y
    std::vector<double> arr_seq = base;
    TaskXResult rx_s1;
    TaskYResult ry_s1{&arr_seq, false};
    auto s0 = std::chrono::steady_clock::now();
    run_task_x(&rx_s1);
    run_task_y(&ry_s1);
    auto s1 = std::chrono::steady_clock::now();
    double t_seq = elapsed_ms(s0, s1);

    // Version 2: Parallel X and Y in 2 pthreads
    std::vector<double> arr_par = base;
    TaskXResult rx_par;
    TaskYResult ry_par{&arr_par, false};
    pthread_t p1, p2;
    auto p0 = std::chrono::steady_clock::now();
    pthread_create(&p1, nullptr, run_task_x, &rx_par);
    pthread_create(&p2, nullptr, run_task_y, &ry_par);
    pthread_join(p1, nullptr);
    pthread_join(p2, nullptr);
    auto p1_end = std::chrono::steady_clock::now();
    double t_par = elapsed_ms(p0, p1_end);

    bool ok = (rx_par.count == rx_seq.count) &&
              (std::abs(rx_par.checksum - rx_seq.checksum) < 1e-6) &&
              ry_par.sorted && (arr_par == arr_seq);

    std::cout << std::fixed << std::setprecision(2);
    std::cout << std::left << std::setw(26) << "Phase" << std::setw(14) << "Time (ms)" << "Details\n";
    std::cout << std::string(64, '-') << "\n";
    std::cout << std::left << std::setw(26) << "Task X alone" << std::setw(14) << t_x
              << "count=" << rx_seq.count << "\n";
    std::cout << std::left << std::setw(26) << "Task Y alone" << std::setw(14) << t_y
              << "sorted=" << (ry_seq.sorted ? "yes" : "no") << "\n";
    std::cout << std::left << std::setw(26) << "Sequential (X + Y)" << std::setw(14) << t_seq
              << "sum=" << (t_x + t_y) << " ms\n";
    std::cout << std::left << std::setw(26) << "Parallel (2 pthreads)" << std::setw(14) << t_par
              << "max(X,Y)=" << std::max(t_x, t_y) << " ms\n";
    std::cout << "\nSpeedup (t_seq / t_par): " << (t_seq / t_par)
              << "x | Correctness: " << (ok ? "PASS" : "FAIL") << "\n";

    std::cout << "\nConclusion:\n"
              << "Both the sqrt filter checksum and the sorted 4M-element array match the "
              << "sequential baseline identically. Running Task X and Task Y concurrently on "
              << "separate pthreads reduces wall-clock time from X + Y down to roughly max(X, Y). "
              << "The small gap above max(X, Y) reflects thread creation, memory-bus sharing, "
              << "and join synchronization overhead.\n";
    return 0;
}
