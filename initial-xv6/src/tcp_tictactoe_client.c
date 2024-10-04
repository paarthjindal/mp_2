#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080

int main()
{
    int sock = 0, valread;
    struct sockaddr_in serv_addr;
    char buffer[1024] = {0};

    // Create socket
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        printf("\n Socket creation error \n");
        return -1;
    }

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    // Convert address from text to binary
    if (inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr) <= 0)
    {
        printf("\nInvalid address/ Address not supported \n");
        return -1;
    }

    // Connect to the server
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
        printf("\nConnection Failed \n");
        return -1;
    }

    printf("Connected to the server.\n");

    // Main loop for receiving messages and sending input
    while (1)
    {
        memset(buffer, 0, sizeof(buffer));

        // Receive message from the server
        valread = recv(sock, buffer, sizeof(buffer), 0);
        if (valread > 0)
        {
            printf("%s", buffer);
            fflush(stdout); // Make sure the output is printed immediately

            // If the server requests input
            if (strstr(buffer, "Your move"))
            {
                // Get the user input for row and column
                printf("Enter row and column: ");
                fgets(buffer, sizeof(buffer), stdin);
                // Strip the newline character, if present
                buffer[strcspn(buffer, "\n")] = '\0'; // Remove the newline character

                // Send input to the server
                send(sock, buffer, strlen(buffer), 0);
            }

            // If the game is over, break the loop
            if (strstr(buffer, "wins") || strstr(buffer, "draw"))
            {
                break;
            }
        }
    }

    close(sock);
    return 0;
}
