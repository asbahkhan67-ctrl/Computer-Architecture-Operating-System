#include <stdio.h>
#include <signal.h>
#include <windows.h>

void my_custom_ignore_function(int signal) {
    printf("\nYou can't close me!\n");
}

int main() {
    signal(SIGINT, my_custom_ignore_function);

    while (1) {
        printf("Running...\n");
        Sleep(1000);
    }

    return 0;
}