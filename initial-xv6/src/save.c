#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <pthread.h>

#define PORT 8080 // we are defining the port no as 8080
#define BOARD_SIZE 9

char board[BOARD_SIZE];
int current_player = 1; // Player 1 = X, Player 2 = O
int move_count = 0;

void initialize_board()
{
    for (int i = 0; i < BOARD_SIZE; i++)
    {
        board[i] = ' ';
    }
}

void display_board(int conn1, int conn2)
{
    char buffer[1024];
    snprintf(buffer, sizeof(buffer),
             "\n %c | %c | %c\n"
             "---+---+---\n"
             " %c | %c | %c\n"
             "---+---+---\n"
             " %c | %c | %c\n\n",
             board[0], board[1], board[2],
             board[3], board[4], board[5],
             board[6], board[7], board[8]);

    // over here i am sending the updated board to both the clients connected to the server
    send(conn1, buffer, strlen(buffer), 0);
    send(conn2, buffer, strlen(buffer), 0);
}

int is_valid_move(int move)
{
    return (move >= 0 && move < BOARD_SIZE && board[move] == ' ');
}

int check_winner()
{
    int win_positions[8][3] = {
        {0, 1, 2}, {3, 4, 5}, {6, 7, 8}, // Rows
        {0, 3, 6},
        {1, 4, 7},
        {2, 5, 8}, // Columns
        {0, 4, 8},
        {2, 4, 6} // Diagonals
    };
    for (int i = 0; i < 8; i++)
    {
        if (board[win_positions[i][0]] != ' ' &&
            board[win_positions[i][0]] == board[win_positions[i][1]] &&
            board[win_positions[i][0]] == board[win_positions[i][2]])
        {
            return current_player;
        }
    }
    return 0;
}

void *handle_client(void *conn_fd)
{
    int conn1 = *((int *)conn_fd);
    free(conn_fd);
    int conn2;

    printf("Player 1 (X) connected.\nWaiting for Player 2...\n");

    // Accept Player 2 connection
    conn2 = accept(conn1, NULL, NULL);
    printf("Player 2 (O) connected.\n");

    initialize_board();

    char buffer[1024];
    int winner = 0;

    while (move_count < BOARD_SIZE)
    {
        display_board(conn1, conn2);

        // Notify current player
        if (current_player == 1)
        {
            send(conn1, "Your turn (X). Enter your move (0-8): ", 40, 0);
            recv(conn1, buffer, sizeof(buffer), 0);
        }
        else
        {
            send(conn2, "Your turn (O). Enter your move (0-8): ", 40, 0);
            recv(conn2, buffer, sizeof(buffer), 0);
        }

        int move = atoi(buffer);

        // Validate move
        if (!is_valid_move(move))
        {
            if (current_player == 1)
            {
                send(conn1, "Invalid move! Try again.\n", 26, 0);
            }
            else
            {
                send(conn2, "Invalid move! Try again.\n", 26, 0);
            }
            continue;
        }

        // Place the move on the board
        board[move] = (current_player == 1) ? 'X' : 'O';
        move_count++;

        // Check for a winner
        if (check_winner())
        {
            winner = current_player;
            break;
        }

        // Switch turns
        current_player = (current_player == 1) ? 2 : 1;
    }

    display_board(conn1, conn2);

    // Notify both players about the result
    if (winner == 1)
    {
        send(conn1, "Congratulations! You win.\n", 27, 0);
        send(conn2, "Player 1 (X) wins. Better luck next time!\n", 42, 0);
    }
    else if (winner == 2)
    {
        send(conn2, "Congratulations! You win.\n", 27, 0);
        send(conn1, "Player 2 (O) wins. Better luck next time!\n", 42, 0);
    }
    else
    {
        send(conn1, "It's a draw!\n", 13, 0);
        send(conn2, "It's a draw!\n", 13, 0);
    }

    close(conn1);
    close(conn2);

    return NULL;
}

int main()
{
    int server_fd, conn_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    // Create socket file descriptor
    // we createad a tcp socket using this
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
    {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    // Attach socket to the port 8080
    // if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt)))
    // {
    //     perror("setsockopt failed");
    //     exit(EXIT_FAILURE);
    // }
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0)
    {
        perror("setsockopt failed");
        exit(EXIT_FAILURE);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    // Bind the socket to the address
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0)
    {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(server_fd, 2) < 0)
    {
        perror("listen failed");
        exit(EXIT_FAILURE);
    }

    printf("Game begins Waiting for players...\n");

    // Accept Player 1 connection
    if ((conn_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0)
    {
        perror("accept failed");
        exit(EXIT_FAILURE);
    }

    // Handle game between two clients
    pthread_t thread_id;
    int *conn_fd_ptr = malloc(sizeof(int));
    *conn_fd_ptr = conn_fd;

    // now i will handle connections
    pthread_create(&thread_id, NULL, handle_client, conn_fd_ptr);
    pthread_join(thread_id, NULL);

    close(server_fd);

    return 0;
}
