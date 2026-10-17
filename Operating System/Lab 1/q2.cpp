#include<iostream>
#include<fstream>
using namespace std;

int main() {
    fstream file;
    file.open("name.txt", ios::out);
    string name = "John Doe";
    file << "Hello, " << name << "!" << endl;
    file.close();
    return 0;
}
