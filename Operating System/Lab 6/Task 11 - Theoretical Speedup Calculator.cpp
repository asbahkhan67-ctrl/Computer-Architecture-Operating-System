#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

// Task 11: Theoretical Speedup Calculator (Amdahl's Law) (C++17)
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <vector>

namespace {

double amdahls_speedup(double p, int N) {
    return 1.0 / ((1.0 - p) + p / static_cast<double>(N));
}

void print_table(double p, int N_max) {
    std::cout << "Parallel fraction p = " << std::fixed << std::setprecision(2) << p
              << " (serial fraction f = " << (1.0 - p)
              << ", max asymptotic speedup = " << std::setprecision(4) << (1.0 / (1.0 - p)) << "x)\n";
    std::cout << std::left << std::setw(8) << "N"
              << std::setw(14) << "S(N)"
              << std::setw(14) << "Eff (%)"
              << "Bar\n";
    std::cout << std::string(56, '-') << "\n";
    for (int N = 1; N <= N_max; ++N) {
        double s = amdahls_speedup(p, N);
        double eff = (s / static_cast<double>(N)) * 100.0;
        int bars = static_cast<int>(s * 2.0 + 0.5);
        std::cout << std::left << std::setw(8) << N
                  << std::setprecision(4) << std::setw(14) << s
                  << std::setprecision(2) << std::setw(14) << eff
                  << std::string(static_cast<std::size_t>(bars), '#') << "\n";
    }
    std::cout << "\n";
}

} // namespace

int main(int argc, char* argv[]) {
    std::cout << "=== Lab 6 Task 11: Theoretical Speedup Calculator (Amdahl's Law) ===\n\n";

    const int N_max = 16;
    if (argc > 1) {
        double p = std::atof(argv[1]);
        if (p <= 0.0 || p >= 1.0) {
            std::cerr << "Provide p in (0, 1), e.g. 0.90\n";
            return 1;
        }
        print_table(p, N_max);
    } else {
        const std::vector<double> fractions = {0.50, 0.75, 0.90, 0.95, 0.99};
        for (double p : fractions) {
            print_table(p, N_max);
        }
    }

    std::cout << "Conclusion:\n"
              << "Amdahl's Law S(N) = 1 / ((1 - p) + p / N) places a strict upper bound of 1 / (1 - p) "
              << "regardless of core count N. At p = 0.50, 16 cores achieve only 1.88x (11.8% efficiency), "
              << "whereas p = 0.95 reaches 9.14x at N = 16. Reducing even a small serial fraction yields "
              << "larger gains at high core counts than adding extra cores.\n";
    return 0;
}
