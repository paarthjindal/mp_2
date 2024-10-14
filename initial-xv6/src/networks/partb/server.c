#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#define MAX_BUFFER 1024
#define CHUNK_SIZE 8
#define TIMEOUT_SEC 0.1
#define MAX_CHUNKS 1024
#define SERVER_PORT 8888

typedef struct
{
    uint32_t seq_num;
    uint32_t total_chunks;
    uint32_t chunk_size; // Add chunk_size to the packet
    char data[CHUNK_SIZE];
} Packet;

typedef struct
{
    int socket;
    struct sockaddr_in addr;
    char recv_buffer[MAX_CHUNKS][CHUNK_SIZE];
    int chunk_sizes[MAX_CHUNKS];     // Add an array to store actual chunk sizes
    int chunks_received[MAX_CHUNKS]; // New: Track received chunks
    int chunks_acked[MAX_CHUNKS];    // New: Track acknowledged chunks
    int expected_seq;
    int total_chunks;
    int all_chunks_received;
} Server;

void die(char *s)
{
    perror(s);
    exit(1);
}

void init_server(Server *server, const char *ip, int port)
{
    server->socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server->socket < 0)
        die("socket creation failed");

    memset(&server->addr, 0, sizeof(server->addr));
    server->addr.sin_family = AF_INET;
    server->addr.sin_addr.s_addr = inet_addr(ip);
    server->addr.sin_port = htons(port);

    if (bind(server->socket, (struct sockaddr *)&server->addr, sizeof(server->addr)) < 0)
        die("bind failed");

    // Set socket to non-blocking mode
    int flags = fcntl(server->socket, F_GETFL, 0);
    fcntl(server->socket, F_SETFL, flags | O_NONBLOCK);

    server->expected_seq = 0;
    server->total_chunks = 0;
}

void send_ack(Server *server, uint32_t seq_num, struct sockaddr_in *client_addr)
{
    uint32_t ack = htonl(seq_num);
    if (sendto(server->socket, &ack, sizeof(ack), 0,
               (struct sockaddr *)client_addr, sizeof(*client_addr)) < 0)
        die("sendto failed");
    server->chunks_acked[seq_num] = 1;
    printf("Sent ACK for chunk %d\n", seq_num);
}

void process_received_data(Server *server)
{
    if (!server->all_chunks_received)
    {
        // Check if all chunks have been received
        server->all_chunks_received = 1;
        for (int i = 0; i < server->total_chunks; i++)
        {
            if (!server->chunks_received[i])
            {
                server->all_chunks_received = 0;
                break;
            }
        }
    }

    // If all chunks have been received and acknowledged, print the message
    if (server->all_chunks_received)
    {
        int all_acked = 1;
        for (int i = 0; i < server->total_chunks; i++)
        {
            if (!server->chunks_acked[i])
            {
                all_acked = 0;
                break;
            }
        }

        if (all_acked)
        {
            printf("All chunks received and acknowledged. Complete message: ");
            for (int i = 0; i < server->total_chunks; i++)
            {
                fwrite(server->recv_buffer[i], 1, server->chunk_sizes[i], stdout);
            }
            printf("\n");

            // Reset for next message
            memset(server->chunks_received, 0, sizeof(server->chunks_received));
            memset(server->chunks_acked, 0, sizeof(server->chunks_acked));
            server->total_chunks = 0;
            server->all_chunks_received = 0;
        }
    }
}
void run_server(const char *ip, int port)
{
    Server server;
    init_server(&server, ip, port);
    memset(server.chunks_received, 0, sizeof(server.chunks_received));
    memset(server.chunks_acked, 0, sizeof(server.chunks_acked));
    server.total_chunks = 0;
    server.all_chunks_received = 0;

    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);

    printf("Server running on %s:%d\n", ip, port);

    while (1)
    {
        Packet recv_packet;
        ssize_t recv_len = recvfrom(server.socket, &recv_packet, sizeof(Packet), 0,
                                    (struct sockaddr *)&client_addr, &addr_len);

        if (recv_len < 0)
        {
            if (errno != EWOULDBLOCK && errno != EAGAIN)
                die("recvfrom failed");
        }
        else if (recv_len == sizeof(Packet))
        {
            recv_packet.seq_num = ntohl(recv_packet.seq_num);
            recv_packet.total_chunks = ntohl(recv_packet.total_chunks);
            recv_packet.chunk_size = ntohl(recv_packet.chunk_size);

            printf("Received chunk %d of %d, size %d\n", recv_packet.seq_num, recv_packet.total_chunks, recv_packet.chunk_size);

            if (recv_packet.seq_num < MAX_CHUNKS)
            {
                memcpy(server.recv_buffer[recv_packet.seq_num], recv_packet.data, recv_packet.chunk_size);
                server.chunk_sizes[recv_packet.seq_num] = recv_packet.chunk_size;
                server.chunks_received[recv_packet.seq_num] = 1;
                server.total_chunks = recv_packet.total_chunks;

                if (rand() % 3 != 0)
                { // 2/3 chance of sending ACK
                    send_ack(&server, recv_packet.seq_num, &client_addr);
                }
                else
                {
                    printf("Randomly skipping ACK for chunk %d\n", recv_packet.seq_num);
                }

                process_received_data(&server);
            }
        }

        usleep(10000); // Sleep for 10ms to prevent busy-waiting
    }
}

int main()
{
    srand(time(NULL)); // Initialize random seed

    char ip[16];
    int port;

    printf("Enter IP address to bind to: ");
    scanf("%s", ip);
    printf("Enter port to bind to: ");
    scanf("%d", &port);

    run_server(ip, port);

    return 0;
}