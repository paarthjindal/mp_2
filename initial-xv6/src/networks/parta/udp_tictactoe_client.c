#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080

int main()
{
    int client_fd;
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);
    char buffer[1024];
    int n;

    // Create UDP socket
    if ((client_fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Send an initial message to the server to indicate connection (could be empty)
    printf("Connected to the server player is ready...\n");
    sendto(client_fd, NULL, 0, 0, (const struct sockaddr *)&server_addr, addr_len);

    // Main game loop
    while (1)
    {
        // Receive message from server
        memset(buffer, 0, sizeof(buffer));
        n = recvfrom(client_fd, buffer, sizeof(buffer), 0, (struct sockaddr *)&server_addr, &addr_len);
        if (n <= 0)
        {
            printf("Server closed the connection or error occurred.\n");
            break;
        }

        buffer[n] = '\0';
        printf("%s", buffer);

        // If the message is asking for input (e.g., your move)
        if (strstr(buffer, "Your move"))
        {
            // Get input from the player
            printf("Enter your move (0-8): ");
            fgets(buffer, sizeof(buffer), stdin);
            buffer[strcspn(buffer, "\n")] = '\0'; // Remove the newline character

            // Send the player's move to the server
            sendto(client_fd, buffer, strlen(buffer), 0, (const struct sockaddr *)&server_addr, addr_len);
        }
        // If the server asks if the player wants to play again
        else if (strstr(buffer, "Do you want to play again?"))
        {
            printf("Enter your response (y/n): ");
            fgets(buffer, sizeof(buffer), stdin);
            buffer[strcspn(buffer, "\n")] = '\0'; // Remove the newline character

            sendto(client_fd, buffer, strlen(buffer), 0, (const struct sockaddr *)&server_addr, addr_len);

            if (buffer[0] == 'n' || buffer[0] == 'N')
            {
                printf("You chose not to play again. Closing connection.\n");
                break;
            }
        }
        // If the game is over (win/draw), but no play-again prompt yet
        else if (strstr(buffer, "wins") || strstr(buffer, "draw"))
        {
            printf("Game over.\n");
        }
    }

    close(client_fd);
    return 0;
}
