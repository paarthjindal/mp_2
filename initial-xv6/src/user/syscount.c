#include "kernel/types.h"
#include "user/user.h"
#include "kernel/syscall.h"

// Function to map the mask to the corresponding syscall name
const char *getSyscallName(int mask)
{
    switch (mask)
    {
    case (1 << (SYS_fork)):
        return "fork";
    case (1 << (SYS_exit)):
        return "exit";
    case (1 << (SYS_wait)):
        return "wait";
    case (1 << (SYS_pipe)):
        return "pipe";
    case (1 << (SYS_read)):
        return "read";
    case (1 << (SYS_kill)):
        return "kill";
    case (1 << (SYS_exec)):
        return "exec";
    case (1 << (SYS_fstat)):
        return "fstat";
    case (1 << (SYS_chdir)):
        return "chdir";
    case (1 << (SYS_dup)):
        return "dup";
    case (1 << (SYS_getpid)):
        return "getpid";
    case (1 << (SYS_sbrk)):
        return "sbrk";
    case (1 << (SYS_sleep)):
        return "sleep";
    case (1 << (SYS_uptime)):
        return "uptime";
    case (1 << (SYS_open)):
        return "open";
    case (1 << (SYS_write)):
        return "write";
    case (1 << (SYS_mknod)):
        return "mknod";
    case (1 << (SYS_unlink)):
        return "unlink";
    case (1 << (SYS_link)):
        return "link";
    case (1 << (SYS_mkdir)):
        return "mkdir";
    case (1 << (SYS_close)):
        return "close";
    case (1 << (SYS_waitx)):
        return "waitx";
    case (1 << (SYS_getSysCount)):
        return "getSysCount";
    default:
        return "unknown";
    }
}

int main(int argc, char *argv[])
{
    // Check if the number of arguments is correct
    if (argc < 3)
    { // Must have at least mask and command
        printf("Usage: syscount <mask> command [args]\n");
        exit(1);
    }

    // Convert the mask argument to an integer
    int mask = atoi(argv[1]);
    if (mask == 0)
    {
        printf("Invalid mask provided.\n");
        exit(1);
    }

    // Fork and run the specified command
    int pid = fork();
    if(pid<0)
    {
        printf("erorr");
        exit(1);
    }
    if (pid == 0)
    {
        // In child process, execute the command
        exec(argv[2], &argv[2]);                // Execute the command
        // printf("Failed to exec %s\n", argv[2]); // Print error if exec fails
        // exit(1);                                // Exit child if exec fails
        exit(0);
    }
    else
    {
        // In parent process, wait for the child to finish
        int wstatus;
        wait(&wstatus);  // Wait for the child process to finish

        // Get the syscall count for the child process
        int count = getSysCount(mask);
        if (count < 0)
        {
            printf("Error in counting syscalls.\n");
        }
        else
        {
            printf("PID %d called %s %d times.\n", pid, getSyscallName(mask), count);
        }
    }

    exit(0); // Exit the parent process
}

// well i am also using syscals like fork exit exec etc in syscount.c , but i dont wanna include them 
// so i need to remove them