#include <stdio.h>

int main() {
    FILE *file;

    file = fopen("does_not_exist.txt", "r");

    if (file == NULL) {
        perror("Error opening file");
        return 1;
    }

    fclose(file);
    return 0;
}