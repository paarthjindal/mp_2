#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>

#define SERVER_PORT 8888
#define CHUNK_SIZE 64
#define TIMEOUT_SEC 0.1

struct Packet
{
    uint32_t seq;
    char data[CHUNK_SIZE];
};

int send_message(int client_sock, const char *message)
{
    int msg_len = strlen(message);
    int total_chunks = (msg_len + CHUNK_SIZE - 1) / CHUNK_SIZE;
    printf("Total chunks: %d\n", total_chunks);

    // Send total number of chunks
    uint32_t total_chunks_net = htonl(total_chunks);
    send(client_sock, &total_chunks_net, sizeof(total_chunks_net), 0);

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
            send(client_sock, &packet, sizeof(uint32_t) + chunk_size, 0);
            printf("Sent chunk %d\n", seq);

            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = TIMEOUT_SEC * 1000000;
            setsockopt(client_sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

            uint32_t ack;
            int received = recv(client_sock, &ack, sizeof(ack), 0);

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
    int server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0)
    {
        perror("Socket creation failed");
        return 1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    server_addr.sin_port = htons(SERVER_PORT);

    if (bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Bind failed");
        return 1;
    }

    if (listen(server_sock, 1) < 0)
    {
        perror("Listen failed");
        return 1;
    }

    printf("Server is listening on port %d...\n", SERVER_PORT);

    struct sockaddr_in client_addr;
    socklen_t client_len = sizeof(client_addr);
    int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &client_len);
    if (client_sock < 0)
    {
        perror("Accept failed");
        return 1;
    }

    printf("Client connected\n");

    const char *message = "Mine name is paarth jindal , i study in iiith";
    send_message(client_sock, message);

    close(client_sock);
    close(server_sock);
    return 0;
}