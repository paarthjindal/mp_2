#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define SENDER_PORT 8888
#define CHUNK_SIZE 8
#define MAX_CHUNKS 1000

struct Packet
{
    uint32_t seq;
    char data[CHUNK_SIZE];
};

int initiate_connection(int sock, struct sockaddr_in *sender_addr)
{
    char connect_msg[] = "CONNECT";
    socklen_t addr_len = sizeof(*sender_addr);

    printf("Initiating connection with sender...\n");
    sendto(sock, connect_msg, strlen(connect_msg), 0, (struct sockaddr *)sender_addr, addr_len);

    char ack[4];
    int received = recvfrom(sock, ack, sizeof(ack), 0, (struct sockaddr *)sender_addr, &addr_len);
    if (received <= 0)
    {
        printf("failed to establish the connection with the server\n");
        return -1;
    }
    if (received > 0 && strcmp(ack, "ACK") == 0)
    {
        printf("Connection established with sender\n");
        return 0;
    }

    printf("Failed to establish connection\n");
    return -1;
}

int all_chunks_acknowledged(int *acked_chunks, int total_chunks)
{
    for (int i = 0; i < total_chunks; i++)
    {
        if (acked_chunks[i] == 0)
        {
            return 0; // If any chunk is not acknowledged, return false
        }
    }
    return 1; // All chunks are acknowledged
}
int receive_message(int sock, struct sockaddr_in *sender_addr)
{
    char *chunks[MAX_CHUNKS] = {0};
    int chunks_received = 0;

    // Receive total number of chunks
    uint32_t total_chunks;
    socklen_t addr_len = sizeof(*sender_addr);
    recvfrom(sock, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)sender_addr, &addr_len);
    total_chunks = ntohl(total_chunks);
    printf("Expecting %d chunks\n", total_chunks);

    int flag = 0; // Toggle flag to simulate ACK loss.
    struct Packet packet;
    int acked_chunks[MAX_CHUNKS] = {0}; // Track which chunks have been acknowledged

    // Continue receiving packets until all chunks are received and acknowledged
    while (chunks_received < total_chunks || !all_chunks_acknowledged(acked_chunks, total_chunks))
    {
        addr_len = sizeof(*sender_addr);
        int received = recvfrom(sock, &packet, sizeof(packet), 0, (struct sockaddr *)sender_addr, &addr_len);

        if (received > 0)
        {
            uint32_t seq = ntohl(packet.seq);

            if (!chunks[seq])
            { // Only process if chunk hasn't been received yet
                printf("Received chunk %d\n", seq);
                chunks[seq] = malloc(CHUNK_SIZE);
                memcpy(chunks[seq], packet.data, CHUNK_SIZE);
                chunks_received++;
            }

            // Send ACK, but simulate random ACK loss (every other packet ACK lost)
            if (flag)
            {
                uint32_t ack = htonl(seq);
                sendto(sock, &ack, sizeof(ack), 0, (struct sockaddr *)sender_addr, sizeof(*sender_addr));
                printf("Sent ACK for chunk %d\n", seq);
                acked_chunks[seq] = 1; // Mark this chunk as acknowledged
                flag = 0;
            }
            else
            {
                flag = 1;
            }
        }
        else
        {
            printf("error in getting connection established\n");
        }
    }

    // Reconstruct the message after all chunks are received
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

    return 0;
}

int main()
{
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0)
    {
        perror("Socket creation failed");
        return 1;
    }

    struct sockaddr_in receiver_addr, sender_addr;
    memset(&receiver_addr, 0, sizeof(receiver_addr));
    receiver_addr.sin_family = AF_INET;
    receiver_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    receiver_addr.sin_port = htons(0); // Use any available port

    if (bind(sock, (struct sockaddr *)&receiver_addr, sizeof(receiver_addr)) < 0)
    {
        perror("Bind failed");
        return 1;
    }

    memset(&sender_addr, 0, sizeof(sender_addr));
    sender_addr.sin_family = AF_INET;
    sender_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Assuming sender is on localhost
    sender_addr.sin_port = htons(SENDER_PORT);

    if (initiate_connection(sock, &sender_addr) < 0)
    {
        close(sock);
        return 1;
    }

    receive_message(sock, &sender_addr);

    close(sock);
    return 0;
}