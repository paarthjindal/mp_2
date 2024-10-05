#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <ctype.h>

#define PORT 8080
#define BOARD_SIZE 9 // 3x3 board

char board[BOARD_SIZE];
int current_player = 1; // Player 1 = X, Player 2 = O
int move_count = 0;
int game_over = 0; // New variable to indicate if the game has ended

pthread_mutex_t turn_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t player_turn_cond = PTHREAD_COND_INITIALIZER;

typedef struct
{
    int player_fd;
    int player_num;
    int other_player_fd; // Added to store the other player's file descriptor
} PlayerData;

// Function to initialize the board
void initialize_board()
{
    for (int i = 0; i < BOARD_SIZE; i++)
    {
        board[i] = ' ';
    }
    move_count = 0;
    current_player = 1;
    game_over = 0; // Reset game_over when starting a new game
}

// Function to display the board
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

    // Send the updated board to both clients
    send(conn1, buffer, strlen(buffer), 0);
    send(conn2, buffer, strlen(buffer), 0);
}

// Function to check if a move is valid
int is_valid_move(int move)
{
    return (move >= 0 && move < BOARD_SIZE && board[move] == ' ');
}

// Function to check for a winner
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
            return current_player; // Return the winning player number
        }
    }
    return 0; // No winner yet
}

// Function to ask both players if they want to play again
int ask_play_again(int player_fd, int other_player_fd)
{
    pthread_mutex_lock(&turn_mutex);

    // printf("overe here\n");
    char buffer[1024];
    int response = 0;

    // Ask both players if they want to play again
    snprintf(buffer, sizeof(buffer), "Do you want to play again? (y/n): ");
    send(player_fd, buffer, strlen(buffer), 0);

    // Inform the other player that the server is waiting for the first player's response
    snprintf(buffer, sizeof(buffer), "Waiting for the other player to decide...\n");
    send(other_player_fd, buffer, strlen(buffer), 0);

    memset(buffer, 0, sizeof(buffer));
    if (recv(player_fd, buffer, sizeof(buffer), 0) <= 0)
    {
        perror("recv error from player_fd");
        return 0; // Player disconnected or error
    }

    int player_response = (buffer[0] == 'y' || buffer[0] == 'Y') ? 1 : 0;

    snprintf(buffer, sizeof(buffer), "Do you want to play again? (y/n): ");
    send(other_player_fd, buffer, strlen(buffer), 0);

    // Inform the first player that the server is waiting for the second player's response
    snprintf(buffer, sizeof(buffer), "Waiting for the other player to decide...\n");
    send(player_fd, buffer, strlen(buffer), 0);

    memset(buffer, 0, sizeof(buffer));
    if (recv(other_player_fd, buffer, sizeof(buffer), 0) <= 0)
    {
        perror("recv error from player_fd");
        return 0; // Other player disconnected or error
    }
    // printf("i am working so hard on debug\n");

    int other_player_response = (buffer[0] == 'y' || buffer[0] == 'Y') ? 1 : 0;
    pthread_mutex_unlock(&turn_mutex);

    if (player_response && other_player_response)
    {
        snprintf(buffer, sizeof(buffer), "Both players agreed to play again! Resetting the board...\n");
        send(player_fd, buffer, strlen(buffer), 0);
        send(other_player_fd, buffer, strlen(buffer), 0);
        return 1; // Both players want to play again
    }
    else if (!player_response && !other_player_response)
    {
        // Both players declined to play again
        snprintf(buffer, sizeof(buffer), "Both players declined to play again. Closing connection.\n");
        send(player_fd, buffer, strlen(buffer), 0);
        send(other_player_fd, buffer, strlen(buffer), 0);
        return 0; // Signal to close the connection
    }
    else
    {
        // One player wants to play again, the other does not
        if (player_response)
        {
            snprintf(buffer, sizeof(buffer), "Your opponent does not wish to play again. Closing connection.\n");
            send(player_fd, buffer, strlen(buffer), 0);
        }
        else
        {
            snprintf(buffer, sizeof(buffer), "Your opponent does not wish to play again. Closing connection.\n");
            send(other_player_fd, buffer, strlen(buffer), 0);
        }

        return 0; // Signal to close the connection
    }
}

// Thread handling function for game logic
void *handle_game(void *arg)
{

    PlayerData *data = (PlayerData *)arg;
    int player_fd = data->player_fd;
    int player_num = data->player_num;
    int other_player_fd = data->other_player_fd; // Access the other player's file descriptor
    free(data);

    char buffer[1024];
    int n, move;
    while (1)
    {
        // display_board(player_fd, other_player_fd); //  i will look into it afterwards to display a new plain board

        while (move_count < BOARD_SIZE)
        {
            pthread_mutex_lock(&turn_mutex);

            // Wait for the current player's turn
            while (current_player != player_num && !game_over)
            {
                snprintf(buffer, sizeof(buffer), "Waiting for Player %d's move...\n", current_player);
                send(player_fd, buffer, strlen(buffer), 0);
                pthread_cond_wait(&player_turn_cond, &turn_mutex);
            }
            if (game_over)
            {
                pthread_mutex_unlock(&turn_mutex);
                break; // Game is over, break the loop
            }

            // Notify the player that it's their turn
            // snprintf(buffer, sizeof(buffer), "Your move (enter position 0-8): ");
            snprintf(buffer, sizeof(buffer), "Your move (%c): Enter the position (0-8): ", (player_num == 1) ? 'X' : 'O');
            send(player_fd, buffer, strlen(buffer), 0);

            // Read player input
            memset(buffer, 0, sizeof(buffer));

            n = recv(player_fd, buffer, sizeof(buffer) - 1, 0);
            if (n <= 0)
            {
                perror("Read error or connection lost");
                // Inform the other player about disconnection
                snprintf(buffer, sizeof(buffer), "Player %d has disconnected.\n", player_num);
                send(other_player_fd, buffer, strlen(buffer), 0);
                close(player_fd);
                pthread_mutex_unlock(&turn_mutex);
                return NULL;
            }
            // printf("input read from mthe user is %s", buffer);
            // Ensure the input is a number
            if (buffer[0] < '0' || buffer[0] > '8' || buffer[1] != '\0')
            {
                printf("are you reaching here\n");
                snprintf(buffer, sizeof(buffer), "Invalid move. Try again.\n");
                send(player_fd, buffer, strlen(buffer), 0);
                pthread_mutex_unlock(&turn_mutex);
                continue;
            }
            // Parse input safely
            move = atoi(buffer);
            // printf("the move is %d\n", move);

            if (move < 0 || move > 8 || buffer[0] < '0' || buffer[0] > '8' || buffer[1] != '\0')
            {
                printf("are you here\n");
                snprintf(buffer, sizeof(buffer), "Invalid move. Try again.\n");
                send(player_fd, buffer, strlen(buffer), 0);
                pthread_mutex_unlock(&turn_mutex);
                continue;
            }

            // Validate the move
            if (!is_valid_move(move))
            {
                printf("why over here");
                snprintf(buffer, sizeof(buffer), "Invalid move. Try again.\n");
                send(player_fd, buffer, strlen(buffer), 0);
                pthread_mutex_unlock(&turn_mutex);
                continue;
            }

            // Update the board with the player's move
            board[move] = (current_player == 1) ? 'X' : 'O';
            move_count++;

            // Display the updated board to both players
            display_board(player_fd, other_player_fd); // Use the local player_fd and other_player_fd

            // Check for a winner
            int winner = check_winner();
            if (winner)
            {
                snprintf(buffer, sizeof(buffer), "Player %d wins!\n", winner);
                send(player_fd, buffer, strlen(buffer), 0);
                send(other_player_fd, buffer, strlen(buffer), 0);
                game_over = 1;                             // Set game over flag
                pthread_cond_broadcast(&player_turn_cond); // Wake up other thread
                pthread_mutex_unlock(&turn_mutex);
                break; // End the game
            }

            // Switch turn to the other player
            current_player = (current_player == 1) ? 2 : 1;
            pthread_cond_broadcast(&player_turn_cond);
            pthread_mutex_unlock(&turn_mutex);
        }
        // printf("main loop ends");
        // Notify both players if the game is a draw
        if (move_count == BOARD_SIZE)
        {
            snprintf(buffer, sizeof(buffer), "It's a draw!\n");
            send(data->player_fd, buffer, strlen(buffer), 0);
            send(other_player_fd, buffer, strlen(buffer), 0);
            game_over = 1;                             // Set game over flag
            pthread_cond_broadcast(&player_turn_cond); // Wake up other thread
            pthread_mutex_unlock(&turn_mutex);
            break;
        }
        // printf("reaching here for regame");
        int play_again = ask_play_again(player_fd, other_player_fd);
        if (!play_again)
        {
            break; // Exit if one or both players don't want to continue
        }

        // Reset the board and start a new game
        initialize_board();
        printf("Player %d: Starting a new game\n", player_num);
    }
    // printf("are you reaching the end\n");
    close(player_fd);
    close(other_player_fd);
    return NULL;
}

int main()
{
    int server_fd, player1_fd, player2_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    // Create socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
    {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    // Attach socket to the port
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)))
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

    printf("Waiting for players...\n");

    // Accept Player 1 connection
    if ((player1_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0)
    {
        perror("accept failed for Player 1");
        exit(EXIT_FAILURE);
    }
    printf("Player 1 connected!\n");

    // Accept Player 2 connection
    if ((player2_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0)
    {
        perror("accept failed for Player 2");
        exit(EXIT_FAILURE);
    }
    printf("Player 2 connected!\n");

    // Notify both players that the game has started
    char start_msg[] = "Both players are connected. Game starting!\n";
    send(player1_fd, start_msg, strlen(start_msg), 0);
    send(player2_fd, start_msg, strlen(start_msg), 0);

    // Create player data
    PlayerData *player1_data = malloc(sizeof(PlayerData));
    player1_data->player_fd = player1_fd;
    player1_data->player_num = 1;
    player1_data->other_player_fd = player2_fd; // Store the other player's fd

    PlayerData *player2_data = malloc(sizeof(PlayerData));
    player2_data->player_fd = player2_fd;
    player2_data->player_num = 2;
    player2_data->other_player_fd = player1_fd; // Store the other player's fd

    initialize_board();

    // Start handling both players
    pthread_t player1_thread, player2_thread;
    pthread_create(&player1_thread, NULL, handle_game, (void *)player1_data);
    pthread_create(&player2_thread, NULL, handle_game, (void *)player2_data);

    // Wait for threads to finish
    pthread_join(player1_thread, NULL);
    pthread_join(player2_thread, NULL);

    // Clean up and close server
    // close(player1_fd);
    // close(player2_fd);
    close(server_fd);

    return 0;
}
