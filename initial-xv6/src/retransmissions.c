#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 8888
#define CHUNK_SIZE 64
#define MAX_CHUNKS 1000

struct Packet
{
    uint32_t seq;
    char data[CHUNK_SIZE];
};

int receive_message()
{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0)
    {
        perror("Socket creation failed");
        return 1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    if (connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Connection failed");
        return 1;
    }

    printf("Connected to server\n");

    char *chunks[MAX_CHUNKS] = {0};
    int chunks_received = 0;

    // Receive total number of chunks
    uint32_t total_chunks;
    recv(sock, &total_chunks, sizeof(total_chunks), 0);
    total_chunks = ntohl(total_chunks);
    printf("Expecting %d chunks\n", total_chunks);

    struct Packet packet;
    while (chunks_received < total_chunks)
    {
        int received = recv(sock, &packet, sizeof(packet), 0);
        if (received <= 0)
        {
            break;
        }

        uint32_t seq = ntohl(packet.seq);
        printf("Received chunk %d\n", seq);

        // Simulate random ACK loss (uncomment for testing)
        // if (rand() % 10 < 3) {
        //     printf("Simulating ACK loss for chunk %d\n", seq);
        //     continue;
        // }

        if (!chunks[seq])
        {
            chunks[seq] = malloc(CHUNK_SIZE);
            memcpy(chunks[seq], packet.data, CHUNK_SIZE);
            chunks_received++;
        }

        // Send ACK
        uint32_t ack = htonl(seq);
        send(sock, &ack, sizeof(ack), 0);
        printf("Sent ACK for chunk %d\n", seq);
    }

    // Reconstruct the message
    char *message = malloc(total_chunks * CHUNK_SIZE + 1);
    int pos = 0;
    for (int i = 0; i < total_chunks; i++)
    {
        memcpy(message + pos, chunks[i], CHUNK_SIZE);
        pos += CHUNK_SIZE;
        free(chunks[i]);
    }
    message[pos] = '\0';

    printf("Received message: %s\n", message);

    free(message);
    close(sock);
    return 0;
}

int main()
{
    receive_message();
    return 0;
}