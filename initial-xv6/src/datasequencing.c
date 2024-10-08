// server.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define CHUNK_SIZE 256
#define PORT 8080
#define MAX_CHUNKS 10

typedef struct
{
    int seq_num;
    int total_chunks;
    char data[CHUNK_SIZE];
} DataChunk;

typedef struct
{
    int ack_num;
} ACKPacket;

void receive_data(int sockfd)
{
    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    DataChunk chunk;
    ACKPacket ack;
    char received_data[MAX_CHUNKS * CHUNK_SIZE] = {0};
    int received_chunks[MAX_CHUNKS] = {0};

    while (1)
    {
        recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_len);
        printf("Received chunk %d: %s\n", chunk.seq_num, chunk.data);

        // Send ACK
        ack.ack_num = chunk.seq_num;
        sendto(sockfd, &ack, sizeof(ack), 0, (struct sockaddr *)&client_addr, addr_len);
        printf("Sent ACK for chunk %d\n", ack.ack_num);

        // Store received chunk
        if (chunk.seq_num <= MAX_CHUNKS)
        {
            strncpy(received_data + (chunk.seq_num - 1) * CHUNK_SIZE, chunk.data, CHUNK_SIZE);
            received_chunks[chunk.seq_num - 1] = 1;
        }

        // Check if all chunks are received
        int all_received = 1;
        for (int i = 0; i < chunk.total_chunks; i++)
        {
            if (!received_chunks[i])
            {
                all_received = 0;
                break;
            }
        }

        if (all_received)
        {
            printf("All chunks received:\n%s\n", received_data);
            break; // Exit loop when all chunks are received
        }
    }
}

int main()
{
    int sockfd;
    struct sockaddr_in server_addr;

    // Create socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("Socket creation failed");
        return EXIT_FAILURE;
    }

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    // Bind the socket
    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Bind failed");
        close(sockfd);
        return EXIT_FAILURE;
    }

    printf("Server listening on port %d...\n", PORT);
    receive_data(sockfd);

    close(sockfd);
    return 0;
}
