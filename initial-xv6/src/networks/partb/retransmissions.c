#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>

#define MAX_MESSAGE_SIZE 1024

#define SENDER_PORT 8888
#define CHUNK_SIZE 8    // i am assuming mine chunk size to be fixed to the value 8
#define MAX_CHUNKS 1000 // can vary this variable according to my needs

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
    while (1)
    {
        int received = recvfrom(sock, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)sender_addr, &addr_len);

        if (received > 0)
        {

            break; // Exit the loop once a valid message is received
        }
        else
        {
            // printf("Error receiving message from client. Retrying...\n");
            continue; // Keep trying until a message is received
        }
    }
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
            size_t data_length = strnlen(packet.data, CHUNK_SIZE); // Get actual data length
            if (!chunks[seq])
            { // Only process if chunk hasn't been received yet
                printf("Received chunk and data%d: %.*s\n", seq, (int)data_length, packet.data);

                chunks[seq] = malloc(strlen(packet.data));
                memcpy(chunks[seq], packet.data, strlen(packet.data));
                chunks_received++;
            }

            // Send ACK, but simulate random ACK loss (every other packet ACK lost)  i commented it out after testing
            // if (flag)
            // {
            uint32_t ack = htonl(seq);
            sendto(sock, &ack, sizeof(ack), 0, (struct sockaddr *)sender_addr, sizeof(*sender_addr));
            printf("Sent ACK for chunk %d\n", seq);
            acked_chunks[seq] = 1; // Mark this chunk as acknowledged
            flag = 0;
            // }
            // else
            // {
            //     flag = 1;
            // }
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
    // printf("Message received successfully. Now waiting for the next message...\n"); // Debugging statement
    char ack_msg[] = "ACK";
    sendto(sock, ack_msg, strlen(ack_msg), 0, (struct sockaddr *)sender_addr, sizeof(*sender_addr));
    printf("Client sent ACK to server after receiving message.\n");
    return 0;
}

// Function to send a message to the server (similar to the server's send_message function)
int send_message(int sock, struct sockaddr_in *receiver_addr, const char *message)
{
    int msg_len = strlen(message);
    printf("Length of the message typed is %d\n", msg_len);
    int total_chunks = (msg_len + CHUNK_SIZE - 1) / CHUNK_SIZE;
    printf("Total chunks to send is: %d\n", total_chunks);

    // Send total number of chunks to the receiver
    uint32_t total_chunks_net = htonl(total_chunks);
    sendto(sock, &total_chunks_net, sizeof(total_chunks_net), 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));

    struct Packet packet;
    int arr[total_chunks]; // Array to keep track of which chunks were acknowledged
    for (int i = 0; i < total_chunks; i++)
    {
        arr[i] = 0;
    }

    // Step 1: Send all chunks without waiting for ACKs
   for (size_t seq = 0; seq < total_chunks; seq++) {
        // Determine the size of the current chunk
        size_t offset = seq * CHUNK_SIZE;
        size_t chunk_size = (offset + CHUNK_SIZE <= msg_len) ? CHUNK_SIZE : (msg_len - offset);

        packet.seq = htonl(seq); // Set sequence number in network byte order
        
        // Copy chunk data into packet
        memcpy(packet.data, message + offset, chunk_size);
        
        // Ensure the remaining data in the packet is zeroed out to prevent garbage values
        memset(packet.data + chunk_size, 0, CHUNK_SIZE - chunk_size); // Zero-fill the remaining part

        // Send the packet
        sendto(sock, &packet, sizeof(uint32_t) + CHUNK_SIZE, 0, (struct sockaddr *)receiver_addr, sizeof(*receiver_addr));
        printf("Sent chunk %zu (size: %zu) value: %.*s\n", seq, chunk_size, CHUNK_SIZE, packet.data); // Log the size of each chunk sent
    }
   


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
                        arr[ack] = 1; // Mark this chunk as acknowledged
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

    // Final acknowledgment from server
    char ack[4];
    socklen_t addr_len = sizeof(*receiver_addr);
    int received = recvfrom(sock, ack, sizeof(ack), 0, (struct sockaddr *)receiver_addr, &addr_len);
    if (received > 0 && strcmp(ack, "ACK") == 0)
    {
        printf("Client received ACK from server.\n");
        return 0; // Proceed after acknowledgment
    }
    else
    {
        printf("Error or no ACK received from server.\n");
        return -1; // Handle error if ACK is not received
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

    char message[MAX_MESSAGE_SIZE];
    while (1)
    {
        // Client receives a message from the server first
        receive_message(sock, &sender_addr);

        // Client sends a message back to the server
        printf("Client: Enter the message to send: ");
        fgets(message, MAX_MESSAGE_SIZE, stdin);
        message[strcspn(message, "\n")] = 0; // Remove trailing newline

        send_message(sock, &sender_addr, message);
    }

    close(sock);
    return 0;
}