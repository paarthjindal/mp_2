// client.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <time.h>
#include <sys/time.h>

#define CHUNK_SIZE 256
#define PORT 8080
#define MAX_CHUNKS 10
#define TIMEOUT 0.1 // 100 ms

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

#include <sys/time.h> // Add this for gettimeofday

void send_data(int sockfd, struct sockaddr_in *server_addr, const char *data)
{
    int total_chunks = (strlen(data) + CHUNK_SIZE - 1) / CHUNK_SIZE; // Calculate total chunks
    DataChunk chunk;
    socklen_t addr_len = sizeof(*server_addr);

    for (int i = 0; i < total_chunks; i++)
    {
        chunk.seq_num = i + 1;
        chunk.total_chunks = total_chunks;
        strncpy(chunk.data, data + i * CHUNK_SIZE, CHUNK_SIZE);

        // Send chunk
        sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)server_addr, addr_len);
        printf("Sent chunk %d: %s\n", chunk.seq_num, chunk.data);

        // Wait for ACK with timeout
        struct timeval start, end;
        gettimeofday(&start, NULL); // Using gettimeofday to measure time

        // Loop for retransmission
        while (1)
        {
            ACKPacket ack;
            fd_set readfds;
            struct timeval timeout;
            timeout.tv_sec = 0;
            timeout.tv_usec = (int)(TIMEOUT * 1000000); // Convert to microseconds

            FD_ZERO(&readfds);        // Clear the set
            FD_SET(sockfd, &readfds); // Add sockfd to the set

            int activity = select(sockfd + 1, &readfds, NULL, NULL, &timeout); // Waiting for ACK
            if (activity > 0 && FD_ISSET(sockfd, &readfds))
            {
                recvfrom(sockfd, &ack, sizeof(ack), 0, NULL, NULL);
                if (ack.ack_num == chunk.seq_num)
                {
                    printf("Received ACK for chunk %d\n", ack.ack_num);
                    break; // Break if valid ACK received
                }
            }
            else
            {
                printf("Timeout! Resending chunk %d\n", chunk.seq_num);
                sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)server_addr, addr_len);
            }

            // Check elapsed time using gettimeofday
            gettimeofday(&end, NULL);
            double elapsed = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1e6; // Time in seconds
            if (elapsed > TIMEOUT)
            {
                printf("Timeout! Resending chunk %d\n", chunk.seq_num);
                sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)server_addr, addr_len);
                gettimeofday(&start, NULL); // Reset timer
            }
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
    server_addr.sin_addr.s_addr = INADDR_ANY; // Server IP
    server_addr.sin_port = htons(PORT);

    // Example data to send
    const char *data_to_send = "This is a sample text to be sent in chunks for demonstrating data sequencing and retransmission logic.";

    // Send data
    send_data(sockfd, &server_addr, data_to_send);

    // Close socket
    close(sockfd);
    return 0;
}
