#include <iostream>
#include <thread>
#include <vector>
using namespace std;

int main() {
    int matrix[3][3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
    int values[3] = {1, 2, 3};
    int result[3] = {};
    vector<thread> workers;

    for (int row = 0; row < 3; ++row) {
        workers.emplace_back([&, row] {
            for (int col = 0; col < 3; ++col)
                result[row] += matrix[row][col] * values[col];
        });
    }
    for (auto& worker : workers) worker.join();

    cout << "Result Vector: [" << result[0] << ", "
         << result[1] << ", " << result[2] << "]\n";
    return 0;
}
