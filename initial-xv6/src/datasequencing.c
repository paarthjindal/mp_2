#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>

#define SERVER_PORT 8888
#define CHUNK_SIZE 64
#define MAX_MESSAGE_SIZE 1024

struct Packet
{
    uint32_t seq;
    char data[CHUNK_SIZE];
};

int wait_for_receiver(int sock, struct sockaddr_in *receiver_addr)
{
    char buffer[16];
    socklen_t addr_len = sizeof(*receiver_addr);

    printf("Waiting for receiver to connect...\n");
    int received = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)receiver_addr, &addr_len);
    if(received<0)
    {
        printf("failed to connect the client\n");
        return -1;
    }
    if (received > 0 && strcmp(buffer, "CONNECT") == 0)
    {
        printf("Receiver is succesfully connected. Sending acknowledgment.\n");
        char ack[] = "ACK";
        sendto(sock, ack, strlen(ack), 0, (struct sockaddr *)receiver_addr, addr_len);
        return 0;
    }

    printf("Failed to establish connection\n");
    return -1;
}

int send_message(int sock, struct sockaddr_in *receiver_addr, const char *message)
{
    int msg_len = strlen(message);
    int total_chunks = (msg_len + CHUNK_SIZE - 1) / CHUNK_SIZE;
    printf("Total chunks: %d\n", total_chunks);

    // Send total number of chunks
    uint32_t total_chunks_net = htonl(total_chunks);
    sendto(sock, &total_chunks_net, sizeof(total_chunks_net), 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));

    struct Packet packet;
    for (int seq = 0; seq < total_chunks; seq++)
    {
        int chunk_size = (seq == total_chunks - 1) ? (msg_len % CHUNK_SIZE) : CHUNK_SIZE;
        if (chunk_size == 0)
            chunk_size = CHUNK_SIZE;

        packet.seq = htonl(seq);
        memcpy(packet.data, message + seq * CHUNK_SIZE, chunk_size);

        int ack_received = 0;
        while (!ack_received)
        {
            sendto(sock, &packet, sizeof(uint32_t) + chunk_size, 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));
            printf("Sent chunk %d\n", seq);

            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = 100000; // 0.1 second timeout
            setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

            uint32_t ack;
            socklen_t addr_len = sizeof(*receiver_addr);
            int received = recvfrom(sock, &ack, sizeof(ack), 0, (struct sockaddr *)receiver_addr, &addr_len);

            if (received > 0)
            {
                ack = ntohl(ack);
                if (ack == seq)
                {
                    ack_received = 1;
                    printf("Received ACK for chunk %d\n", seq);
                }
            }
            else
            {
                printf("Timeout waiting for ACK of chunk %d, retransmitting\n", seq);
            }
        }
    }

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

    struct sockaddr_in sender_addr, receiver_addr;
    memset(&sender_addr, 0, sizeof(sender_addr));
    sender_addr.sin_family = AF_INET;
    sender_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    sender_addr.sin_port = htons(SERVER_PORT);

    if (bind(sock, (struct sockaddr *)&sender_addr, sizeof(sender_addr)) < 0)
    {
        perror("Bind failed");
        return 1;
    }

    if (wait_for_receiver(sock, &receiver_addr) < 0)
    {
        close(sock);
        return 1;
    }

    char message[MAX_MESSAGE_SIZE];
    printf("Enter the message to send: ");
    fgets(message, MAX_MESSAGE_SIZE, stdin);
    message[strcspn(message, "\n")] = 0; // Remove trailing newline

    send_message(sock, &receiver_addr, message);

    close(sock);
    return 0;
}
