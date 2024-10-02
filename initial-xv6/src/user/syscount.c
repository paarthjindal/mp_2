#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: syscount <mask> command [args]\n");
        exit(1);
    }

    int mask = atoi(argv[1]);
    if (mask == 0) {
        printf("Invalid mask provided.\n");
        exit(1);
    }

    // Fork and run the specified command
    if (fork() == 0) {
        // In child process, execute the command
        exec(argv[2], &argv[2]);
        exit(0);
    } else {
        // In parent process, wait for child and get system call count
        wait(0);
        int count = getSysCount(mask);
        if (count < 0) {
            printf("Error in counting syscalls.\n");
        } else {
            printf("PID %d called %d syscalls\n", getpid(), count);
        }
    }

    exit(0);
}
