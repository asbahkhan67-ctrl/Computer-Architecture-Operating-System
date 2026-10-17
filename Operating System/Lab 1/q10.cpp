#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    int pid = fork();

    if (pid < 0) {
        printf("Fork failed!\n");
    }
    else if (pid == 0) {
        // Child process
        printf("I am the child\n");
        sleep(2);
        printf("Child is finished\n");
    }
    else {
        // Parent process
        printf("I am the parent\n");
        wait(NULL);
        printf("All done!\n");
    }

    return 0;
}