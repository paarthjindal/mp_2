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
int game_over = 0;

pthread_mutex_t turn_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t player_turn_cond = PTHREAD_COND_INITIALIZER;

typedef struct
{
    int player_num;
    struct sockaddr_in player_addr;
    struct sockaddr_in other_player_addr;
    socklen_t addr_len;
    int server_fd; // UDP socket descriptor
} PlayerData;

void initialize_board()
{
    for (int i = 0; i < BOARD_SIZE; i++)
    {
        board[i] = ' ';
    }
    move_count = 0;
    current_player = 1;
    game_over = 0;
}

void display_board(int server_fd, struct sockaddr_in *player1_addr, struct sockaddr_in *player2_addr, socklen_t addr_len)
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
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)player1_addr, addr_len);
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)player2_addr, addr_len);
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

// Function to ask both players if they want to play again
int ask_play_again(int server_fd, struct sockaddr_in player_addr, struct sockaddr_in other_player_addr, socklen_t addr_len)
{
    char buffer[1024];

    // Step 1: Ask the first player if they want to play again
    snprintf(buffer, sizeof(buffer), "Do you want to play again? (y/n): ");
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);

    // Inform the other player that the server is waiting for the first player's response
    snprintf(buffer, sizeof(buffer), "Waiting for the other player to decide...\n");
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);

    // Get response from the first player
    memset(buffer, 0, sizeof(buffer));
    recvfrom(server_fd, buffer, sizeof(buffer), 0, (struct sockaddr *)&player_addr, &addr_len);
    int player_response = (buffer[0] == 'y' || buffer[0] == 'Y') ? 1 : 0;

    // Step 2: Ask the second player if they want to play again
    snprintf(buffer, sizeof(buffer), "Do you want to play again? (y/n): ");
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);

    // Inform the first player that the server is waiting for the second player's response
    snprintf(buffer, sizeof(buffer), "Waiting for the other player to decide...\n");
    sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);

    // Get response from the second player
    memset(buffer, 0, sizeof(buffer));
    recvfrom(server_fd, buffer, sizeof(buffer), 0, (struct sockaddr *)&other_player_addr, &addr_len);
    int other_player_response = (buffer[0] == 'y' || buffer[0] == 'Y') ? 1 : 0;

    // Step 3: Check and handle both players' responses
    if (player_response && other_player_response)
    {
        // Both players want to play again
        snprintf(buffer, sizeof(buffer), "Both players agreed to play again! Resetting the board...\n");
        sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
        sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
        return 1; // Continue playing
    }
    else if (!player_response && !other_player_response)
    {
        // Both players declined to play again
        snprintf(buffer, sizeof(buffer), "Both players declined to play again. Closing connection.\n");
        sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
        sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
        return 0; // End the game
    }
    else
    {
        // One player wants to continue while the other does not
        snprintf(buffer, sizeof(buffer), "Your opponent does not wish to play again. Closing connection.\n");
        if (player_response)
        {
            // Inform the first player that the second player declined
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
        }
        else
        {
            // Inform the second player that the first player declined
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
        }
        return 0; // End the game
    }
}

// Thread handling function for game logic
void *handle_game(void *arg)
{
    PlayerData *data = (PlayerData *)arg;
    struct sockaddr_in player_addr = data->player_addr;
    struct sockaddr_in other_player_addr = data->other_player_addr;
    socklen_t addr_len = data->addr_len;
    int server_fd = data->server_fd;
    int player_num = data->player_num;
    free(data);

    char buffer[1024];
    int move, n;

    while (1)
    {
        while (move_count < BOARD_SIZE)
        {
            pthread_mutex_lock(&turn_mutex);

            while (current_player != player_num && !game_over)
            {
                snprintf(buffer, sizeof(buffer), "Waiting for Player %d's move...\n", current_player);
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
                pthread_cond_wait(&player_turn_cond, &turn_mutex);
            }
            if (game_over)
            {
                pthread_mutex_unlock(&turn_mutex);
                break;
            }

            snprintf(buffer, sizeof(buffer), "Your move (%c): Enter the position (0-8): ", (player_num == 1) ? 'X' : 'O');
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);

            memset(buffer, 0, sizeof(buffer));
            n = recvfrom(server_fd, buffer, sizeof(buffer), 0, (struct sockaddr *)&player_addr, &addr_len);
            if (n <= 0)
            {
                perror("Read error or connection lost");
                snprintf(buffer, sizeof(buffer), "Player %d has disconnected.\n", player_num);
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
                close(server_fd);
                pthread_mutex_unlock(&turn_mutex);
                return NULL;
            }

            if (buffer[0] < '0' || buffer[0] > '8' || buffer[1] != '\0')
            {
                snprintf(buffer, sizeof(buffer), "Invalid move. Try again.\n");
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
                pthread_mutex_unlock(&turn_mutex);
                continue;
            }

            move = atoi(buffer);
            if (!is_valid_move(move))
            {
                snprintf(buffer, sizeof(buffer), "Invalid move. Try again.\n");
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
                pthread_mutex_unlock(&turn_mutex);
                continue;
            }

            board[move] = (current_player == 1) ? 'X' : 'O';
            move_count++;

            display_board(server_fd, &player_addr, &other_player_addr, addr_len);

            int winner = check_winner();
            if (winner)
            {
                snprintf(buffer, sizeof(buffer), "Player %d wins!\n", winner);
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
                sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
                game_over = 1;
                pthread_cond_broadcast(&player_turn_cond);
                pthread_mutex_unlock(&turn_mutex);
                break;
            }

            current_player = (current_player == 1) ? 2 : 1;
            pthread_cond_broadcast(&player_turn_cond);
            pthread_mutex_unlock(&turn_mutex);
        }

        if (move_count == BOARD_SIZE)
        {
            snprintf(buffer, sizeof(buffer), "It's a draw!\n");
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&player_addr, addr_len);
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&other_player_addr, addr_len);
            game_over = 1;
            pthread_cond_broadcast(&player_turn_cond);
            break;
        }
        if (!ask_play_again(server_fd, player_addr, other_player_addr, addr_len))
        {
            break; // Handle the scenario when players don't want to play again
        }
    }

    close(server_fd);
    return NULL;
}

int main()
{
    int server_fd;
    struct sockaddr_in server_addr, player1_addr, player2_addr;
    socklen_t addr_len = sizeof(struct sockaddr_in);

    // Creating a UDP socket
    if ((server_fd = socket(AF_INET, SOCK_DGRAM, 0)) == 0)
    {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    // Wait for both players to connect
    printf("Waiting for Player 1...\n");
    recvfrom(server_fd, NULL, 0, 0, (struct sockaddr *)&player1_addr, &addr_len);
    printf("Player 1 connected!\n");

    printf("Waiting for Player 2...\n");
    recvfrom(server_fd, NULL, 0, 0, (struct sockaddr *)&player2_addr, &addr_len);
    printf("Player 2 connected!\n");

    // Initialize the game board
    initialize_board();

    // Create threads for each player
    pthread_t player1_thread, player2_thread;

    PlayerData *player1_data = (PlayerData *)malloc(sizeof(PlayerData));
    player1_data->player_num = 1;
    player1_data->player_addr = player1_addr;
    player1_data->other_player_addr = player2_addr;
    player1_data->addr_len = addr_len;
    player1_data->server_fd = server_fd;

    PlayerData *player2_data = (PlayerData *)malloc(sizeof(PlayerData));
    player2_data->player_num = 2;
    player2_data->player_addr = player2_addr;
    player2_data->other_player_addr = player1_addr;
    player2_data->addr_len = addr_len;
    player2_data->server_fd = server_fd;

    pthread_create(&player1_thread, NULL, handle_game, (void *)player1_data);
    pthread_create(&player2_thread, NULL, handle_game, (void *)player2_data);

    // Wait for the game to finish
    pthread_join(player1_thread, NULL);
    pthread_join(player2_thread, NULL);

    return 0;
}
