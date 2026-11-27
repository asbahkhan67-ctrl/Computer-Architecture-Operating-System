#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Lab 7 Task 18: Multi-Core Scalability on CPU-Bound Workloads (1:N ULT vs. 1:1 KLT) (C++17)
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <pthread.h>
#include <ucontext.h>
#include <vector>

using namespace std;

namespace {

constexpr int MATRIX_DIM = 512;
constexpr int NUM_WORKERS = 4;
constexpr size_t STK_SIZE = 32768;

vector<double> g_A, g_B, g_C_ult, g_C_klt;

void matrix_multiply_subsegment(int start_row, int end_row, double* C_out) {
    for (int i = start_row; i < end_row; ++i) {
        for (int j = 0; j < MATRIX_DIM; ++j) {
            double s = 0.0;
            for (int k = 0; k < MATRIX_DIM; ++k) {
                s += g_A[static_cast<size_t>(i) * MATRIX_DIM + k] *
                     g_B[static_cast<size_t>(k) * MATRIX_DIM + j];
            }
            C_out[static_cast<size_t>(i) * MATRIX_DIM + j] = s;
        }
    }
}

// --- Test Case A: 4 ULTs inside 1 KLT ---
ucontext_t g_sched_ctx, g_ult_ctx[NUM_WORKERS];
char g_ult_stk[NUM_WORKERS][STK_SIZE];
int g_cur_ult = 0;

void ult_matmul_entry() {
    int id = g_cur_ult;
    int rows = MATRIX_DIM / NUM_WORKERS;
    matrix_multiply_subsegment(id * rows, (id + 1) * rows, g_C_ult.data());
    setcontext(&g_sched_ctx);
}

// --- Test Case B: 4 KLTs (pthreads) ---
void* klt_matmul_entry(void* arg) {
    int id = *static_cast<int*>(arg);
    int rows = MATRIX_DIM / NUM_WORKERS;
    matrix_multiply_subsegment(id * rows, (id + 1) * rows, g_C_klt.data());
    return nullptr;
}

} // namespace

int main() {
    cout << "=== Lab 7 Task 18: Multi-Core Scalability (4 ULTs vs. 4 KLTs on "
         << MATRIX_DIM << "x" << MATRIX_DIM << " MatMul) ===\n\n";

    g_A.resize(MATRIX_DIM * MATRIX_DIM);
    g_B.resize(MATRIX_DIM * MATRIX_DIM);
    g_C_ult.assign(MATRIX_DIM * MATRIX_DIM, 0.0);
    g_C_klt.assign(MATRIX_DIM * MATRIX_DIM, 0.0);

    for (int i = 0; i < MATRIX_DIM * MATRIX_DIM; ++i) {
        g_A[static_cast<size_t>(i)] = static_cast<double>((i % 17) + 1) * 0.1;
        g_B[static_cast<size_t>(i)] = static_cast<double>((i % 13) + 1) * 0.05;
    }

    // Test Case A: 4 ULTs on 1 kernel thread
    for (int i = 0; i < NUM_WORKERS; ++i) {
        getcontext(&g_ult_ctx[i]);
        g_ult_ctx[i].uc_stack.ss_sp = g_ult_stk[i];
        g_ult_ctx[i].uc_stack.ss_size = STK_SIZE;
        g_ult_ctx[i].uc_link = &g_sched_ctx;
        makecontext(&g_ult_ctx[i], ult_matmul_entry, 0);
    }

    auto u0 = chrono::steady_clock::now();
    for (int i = 0; i < NUM_WORKERS; ++i) {
        g_cur_ult = i;
        swapcontext(&g_sched_ctx, &g_ult_ctx[i]);
    }
    auto u1 = chrono::steady_clock::now();
    double ult_ms = chrono::duration<double, milli>(u1 - u0).count();

    // Test Case B: 4 pthreads across cores
    pthread_t th[NUM_WORKERS];
    int ids[NUM_WORKERS] = {0, 1, 2, 3};
    auto k0 = chrono::steady_clock::now();
    for (int i = 0; i < NUM_WORKERS; ++i) {
        pthread_create(&th[i], nullptr, klt_matmul_entry, &ids[i]);
    }
    for (int i = 0; i < NUM_WORKERS; ++i) {
        pthread_join(th[i], nullptr);
    }
    auto k1 = chrono::steady_clock::now();
    double klt_ms = chrono::duration<double, milli>(k1 - k0).count();

    double max_err = 0.0;
    for (size_t i = 0; i < g_C_ult.size(); ++i) {
        max_err = max(max_err, fabs(g_C_ult[i] - g_C_klt[i]));
    }

    cout << fixed << setprecision(2);
    cout << "ULT Completion Wall-Clock (1 KLT):  " << ult_ms << " ms\n";
    cout << "KLT Completion Wall-Clock (4 KLTs): " << klt_ms << " ms\n";
    cout << "Multi-Core Speedup (ULT / KLT):     " << (ult_ms / klt_ms) << "x\n";
    cout << "Correctness (max diff < 1e-6):      " << (max_err < 1e-6 ? "PASS" : "FAIL") << "\n";
    return 0;
}
