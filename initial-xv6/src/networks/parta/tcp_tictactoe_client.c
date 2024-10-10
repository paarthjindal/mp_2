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

            // If the server requests the player's move
            if (strstr(buffer, "Your move"))
            {
                // Get the user input for row and column
                printf("Enter row and column: ");
                fgets(buffer, sizeof(buffer), stdin);
                buffer[strcspn(buffer, "\n")] = '\0'; // Remove the newline character

                // Send the input to the server
                send(sock, buffer, strlen(buffer), 0);
            }

            // If the server asks if the player wants to play again
            else if (strstr(buffer, "Do you want to play again?"))
            {
                // Get the user's response (y/n)
                printf("Enter your response (y/n): ");
                fgets(buffer, sizeof(buffer), stdin);
                buffer[strcspn(buffer, "\n")] = '\0'; // Remove the newline character

                // Send the response to the server
                send(sock, buffer, strlen(buffer), 0);

                // If the player says no, exit the loop
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
                // Continue to wait for play again prompt instead of breaking immediately
            }
        }
        else if (valread == 0)
        {
            printf("Server closed the connection.\n");
            break;
        }
        else
        {
            perror("recv error");
            break;
        }
    }

    close(sock);
    return 0;
}
