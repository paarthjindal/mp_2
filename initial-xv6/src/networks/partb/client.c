#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <fcntl.h>
#include <errno.h>

#define MAX_BUFFER 1024
#define CHUNK_SIZE 8
#define TIMEOUT_SEC 0.1
#define MAX_CHUNKS 1024 // i am assuming maximum no of chunks cant go ahead of 1024
#define SERVER_PORT 8888

typedef struct
{
    uint32_t seq_num;
    uint32_t total_chunks;
    uint32_t chunk_size;
    char data[CHUNK_SIZE];
} Packet;

typedef struct
{
    int socket;
    struct sockaddr_in addr;
    Packet send_buffer[MAX_CHUNKS];
    // over here storing last sent time of each chunk
    struct timeval last_send_time[MAX_CHUNKS];
    int sent[MAX_CHUNKS];          // Track if the packet has been initially sent
    int acks_received[MAX_CHUNKS]; // New: Track ACKs for each chunk
    int total_chunks;
} Client;

void die(char *s)
{
    perror(s);
    exit(1);
}

void init_client(Client *client, const char *ip, int port)
{
    client->socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client->socket < 0)
        die("socket creation failed");

    memset(&client->addr, 0, sizeof(client->addr));
    client->addr.sin_family = AF_INET;
    client->addr.sin_addr.s_addr = inet_addr(ip);
    client->addr.sin_port = htons(port);

    // Set socket to non-blocking mode
    int flags = fcntl(client->socket, F_GETFL, 0);
    fcntl(client->socket, F_SETFL, flags | O_NONBLOCK);

    client->total_chunks = 0;
}

void send_packet(Client *client, Packet *packet)
{
    if (sendto(client->socket, packet, sizeof(Packet), 0,
               (struct sockaddr *)&client->addr, sizeof(client->addr)) < 0)
        die("sendto failed");
}

void divide_data(const char *data, Client *client)
{
    int data_len = strlen(data);
    client->total_chunks = (data_len + CHUNK_SIZE - 1) / CHUNK_SIZE;

    for (int i = 0; i < client->total_chunks; i++)
    {
        client->send_buffer[i].seq_num = htonl(i);
        client->send_buffer[i].total_chunks = htonl(client->total_chunks);

        int chunk_size = (i == client->total_chunks - 1) ? data_len - i * CHUNK_SIZE : CHUNK_SIZE;
        client->send_buffer[i].chunk_size = htonl(chunk_size); // Set the actual chunk size

        memcpy(client->send_buffer[i].data, data + i * CHUNK_SIZE, chunk_size);
        memset(client->send_buffer[i].data + chunk_size, 0, CHUNK_SIZE - chunk_size); // Zero-pad the rest

        gettimeofday(&client->last_send_time[i], NULL);
    }
}

// void handle_retransmissions(Client *client)
// {
//     struct timeval now;
//     gettimeofday(&now, NULL);

//     for (int i = 0; i < client->total_chunks; i++)
//     {
//         int can_send_new_packet = 1; // Assume we can send the new packet

//         // Inner loop: Check all previous packets for acknowledgment
//         for (int j = 0; j < i; j++)
//         {
//             if (!client->acks_received[j])
//             {
//                 // If previous packet has not been acknowledged, check if it needs retransmission
//                 double elapsed = (now.tv_sec - client->last_send_time[j].tv_sec) +
//                                  (now.tv_usec - client->last_send_time[j].tv_usec) / 1000000.0;

//                 if (elapsed > TIMEOUT_SEC)
//                 {
//                     // Retransmit the unacknowledged previous packet
//                     printf("Retransmitting chunk %d\n", j);
//                     send_packet(client, &client->send_buffer[j]);
//                     gettimeofday(&client->last_send_time[j], NULL);
//                 }

//                 can_send_new_packet = 0; // Block sending the new packet if previous packet is not acknowledged
//             }
//         }

//         // If all previous packets are acknowledged, send the new packet
//         if (can_send_new_packet && !client->acks_received[i])
//         {
//             // If packet hasn't been sent before, send it now
//             if (!client->sent[i])
//             {
//                 printf("Sending chunk %d\n", i);
//                 send_packet(client, &client->send_buffer[i]);
//                 gettimeofday(&client->last_send_time[i], NULL);
//                 client->sent[i] = 1; // Mark packet as sent
//             }
//         }
//     }
// }

void handle_retransmissions(Client *client)
{
    struct timeval now;
    gettimeofday(&now, NULL);

    for (int i = 0; i < client->total_chunks; i++)
    {
        if (!client->acks_received[i])  // checking if already acknowldgement recivued then no need to send it again
        {
            // Check if the packet has been sent at least once
            if (!client->sent[i])
            {
                // First-time sending this packet
                printf("Sending chunk %d\n", i);
                send_packet(client, &client->send_buffer[i]);
                gettimeofday(&client->last_send_time[i], NULL);
                client->sent[i] = 1; // Mark this packet as sent
            }
            else
            {
                // This packet has been sent before, check if it needs retransmission
                double elapsed = (now.tv_sec - client->last_send_time[i].tv_sec) +
                                 (now.tv_usec - client->last_send_time[i].tv_usec) / 1000000.0;

                if (elapsed > TIMEOUT_SEC)
                {
                    printf("Retransmitting chunk %d\n", i);
                    send_packet(client, &client->send_buffer[i]);
                    gettimeofday(&client->last_send_time[i], NULL);
                }
            }
        }
    }
}

void run_client(const char *server_ip, int server_port)
{
    Client client;
    init_client(&client, server_ip, server_port);
    memset(client.acks_received, 0, sizeof(client.acks_received)); // Initialize ACKs tracking

    char message[MAX_BUFFER];
    printf("Enter message to send: ");
    fgets(message, sizeof(message), stdin);
    message[strcspn(message, "\n")] = 0; // Remove trailing newline

    divide_data(message, &client);

    printf("Sending message to server %s:%d\n", server_ip, server_port);

    int all_acks_received = 0;

    while (!all_acks_received)
    {
        handle_retransmissions(&client);

        uint32_t ack;
        ssize_t recv_len = recvfrom(client.socket, &ack, sizeof(ack), 0, NULL, NULL);

        if (recv_len < 0)
        {
            if (errno != EWOULDBLOCK && errno != EAGAIN)
                die("recvfrom failed");
        }
        else if (recv_len == sizeof(uint32_t))
        {
            uint32_t ack_seq = ntohl(ack);
            printf("Received ACK for chunk %d\n", ack_seq);
            client.acks_received[ack_seq] = 1;

            all_acks_received = 1;
            for (int i = 0; i < client.total_chunks; i++)
            {
                if (!client.acks_received[i])
                {
                    all_acks_received = 0;
                    break;
                }
            }
        }

        usleep(10000); // Sleep for 10ms to prevent busy-waiting
    }

    printf("All chunks acknowledged. Message sent successfully.\n");
}

int main()
{
    char server_ip[16];
    int server_port;

    printf("Enter server IP: ");
    scanf("%s", server_ip);
    printf("Enter server port: ");
    scanf("%d", &server_port);
    getchar(); // Consume newline

    run_client(server_ip, server_port);

    return 0;
}
