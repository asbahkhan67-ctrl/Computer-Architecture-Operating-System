#include <stdio.h>
#include <unistd.h>

int main() {
    int pid = fork();

    if (pid == 0) {
        printf("I am the child\n");
    }
    else if (pid > 0) {
        printf("I am the parent\n");
    }
    else {
        printf("Fork failed\n");
    }

    return 0;
}