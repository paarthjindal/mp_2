#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>

#define SERVER_PORT 8888
#define CHUNK_SIZE 8
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
    if (received <= 0)
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

    printf("Failed to establish connection between server and the client\n");
    return -1;
}

int send_message(int sock, struct sockaddr_in *receiver_addr, const char *message)
{
    int msg_len = strlen(message);
    printf("Length of the message typed is %d\n", msg_len);
    int total_chunks = (msg_len + CHUNK_SIZE - 1) / CHUNK_SIZE;
    printf("Total chunks to send is : %d\n", total_chunks);

    // Send total number of chunks to the receiver
    uint32_t total_chunks_net = htonl(total_chunks);
    sendto(sock, &total_chunks_net, sizeof(total_chunks_net), 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));

    struct Packet packet;
    int arr[total_chunks];                // Array to keep track of which chunks were acknowledged
    for (int i = 0; i < total_chunks; i++)
    {
        arr[i]=0;
    }
     

    // Step 1: Send all chunks without waiting for ACKs
    for (int seq = 0; seq < total_chunks; seq++)
    {
        int chunk_size = (seq == total_chunks - 1) ? (msg_len % CHUNK_SIZE) : CHUNK_SIZE;
        if (chunk_size == 0)
            chunk_size = CHUNK_SIZE;

        packet.seq = htonl(seq);                                     // Sequence number in network byte order
        memcpy(packet.data, message + seq * CHUNK_SIZE, chunk_size); // Copy chunk data

        sendto(sock, &packet, sizeof(uint32_t) + chunk_size, 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));
        printf("Sent chunk %d\n", seq);
    }

    // Step 2: Process acknowledgments and handle retransmissions if necessary
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 100000; // 0.1 second timeout
    // The setsockopt() function is used to set a timeout oon the socket for receiving the ACK
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    while (1)
    {
        int all_ack_received = 1; // Assume all ACKs are received
        for (int seq = 0; seq < total_chunks; seq++)
        {
            if (arr[seq] == 0) // If ACK for this chunk hasn't been received
            {
                all_ack_received = 0; // Not all ACKs received
                uint32_t ack;
                socklen_t addr_len = sizeof(*receiver_addr);
                int received = recvfrom(sock, &ack, sizeof(ack), 0, (struct sockaddr *)receiver_addr, &addr_len);

                if (received > 0)
                {
                    ack = ntohl(ack);
                    if (ack >= 0 && ack < total_chunks && arr[ack] == 0)
                    {
                        arr[ack] = 1;
                        printf("Received ACK for chunk %d\n", ack);
                    }
                }

                // Resend chunks that haven't been acknowledged
                if (arr[seq] == 0)
                {
                    int chunk_size = (seq == total_chunks - 1) ? (msg_len % CHUNK_SIZE) : CHUNK_SIZE;
                    if (chunk_size == 0)
                        chunk_size = CHUNK_SIZE;

                    packet.seq = htonl(seq);
                    memcpy(packet.data, message + seq * CHUNK_SIZE, chunk_size);

                    sendto(sock, &packet, sizeof(uint32_t) + chunk_size, 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));
                    printf("Resent chunk %d\n", seq);
                }
            }
        }

        if (all_ack_received)
        {
            printf("All chunks acknowledged.\n");
            break;
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
