// eBPF Program for IMDSv2 Metadata Blocking
// This program blocks direct metadata access and enforces IMDSv2 tokens
// 
// Features:
// - Blocks direct access to 169.254.169.254:80 (metadata service)
// - Allows only PUT requests to /latest/api/token (token endpoint)
// - Logs blocked attempts for monitoring
// - More efficient than iptables rules

#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/in.h>
#include <linux/string.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// Metadata service IP and port
#define METADATA_IP 0xFE169254  // 169.254.169.254 in network byte order
#define METADATA_PORT 80
#define TOKEN_PATH "/latest/api/token"
#define TOKEN_PATH_LEN 18

// Map for storing blocked connection attempts
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1000);
    __type(key, __u32);
    __type(value, __u64);
} blocked_attempts SEC(".maps");

// Map for storing allowed token requests
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 100);
    __type(key, __u32);
    __type(value, __u64);
} token_requests SEC(".maps");

// Helper function to check if packet is TCP
static inline int is_tcp(struct iphdr *ip) {
    return ip->protocol == IPPROTO_TCP;
}

// Helper function to check if packet is UDP
static inline int is_udp(struct iphdr *ip) {
    return ip->protocol == IPPROTO_UDP;
}

// Helper function to get TCP header
static inline struct tcphdr *get_tcp_header(struct iphdr *ip) {
    return (struct tcphdr *)((char *)ip + (ip->ihl * 4));
}

// Helper function to check if destination is metadata service
static inline int is_metadata_destination(struct iphdr *ip) {
    return ip->daddr == METADATA_IP;
}

// Helper function to check if destination port is metadata port
static inline int is_metadata_port(struct tcphdr *tcp) {
    return bpf_ntohs(tcp->dest) == METADATA_PORT;
}

// Helper function to check if request is PUT to token endpoint
static inline int is_token_request(struct tcphdr *tcp, void *data_end) {
    // Check if this is a PUT request to /latest/api/token
    char *payload = (char *)tcp + (tcp->doff * 4);
    
    // Ensure we don't read beyond packet boundary
    if (payload + 200 > data_end) {
        return 0;
    }
    
    // Check for PUT method and token path
    if (bpf_strncmp(payload, "PUT", 3) == 0) {
        char *path_start = payload;
        while (path_start < data_end && *path_start != ' ') {
            path_start++;
        }
        if (path_start < data_end) {
            path_start++; // Skip space
            if (bpf_strncmp(path_start, TOKEN_PATH, TOKEN_PATH_LEN) == 0) {
                return 1;
            }
        }
    }
    
    return 0;
}

// Helper function to log blocked attempt
static inline void log_blocked_attempt(__u32 src_ip) {
    __u64 *count = bpf_map_lookup_elem(&blocked_attempts, &src_ip);
    if (count) {
        (*count)++;
    } else {
        __u64 initial_count = 1;
        bpf_map_update_elem(&blocked_attempts, &src_ip, &initial_count, BPF_ANY);
    }
}

// Helper function to log token request
static inline void log_token_request(__u32 src_ip) {
    __u64 *count = bpf_map_lookup_elem(&token_requests, &src_ip);
    if (count) {
        (*count)++;
    } else {
        __u64 initial_count = 1;
        bpf_map_update_elem(&token_requests, &src_ip, &initial_count, BPF_ANY);
    }
}

// Main eBPF program for XDP (eXpress Data Path)
SEC("xdp_metadata_blocker")
int xdp_metadata_blocker(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    // Parse Ethernet header
    struct ethhdr *eth = data;
    if (data + sizeof(*eth) > data_end) {
        return XDP_PASS;
    }
    
    // Check if this is an IP packet
    if (eth->h_proto != bpf_htons(ETH_P_IP)) {
        return XDP_PASS;
    }
    
    // Parse IP header
    struct iphdr *ip = data + sizeof(*eth);
    if (data + sizeof(*eth) + sizeof(*ip) > data_end) {
        return XDP_PASS;
    }
    
    // Check if destination is metadata service
    if (!is_metadata_destination(ip)) {
        return XDP_PASS;
    }
    
    // Check if this is a TCP packet
    if (!is_tcp(ip)) {
        return XDP_PASS;
    }
    
    // Parse TCP header
    struct tcphdr *tcp = get_tcp_header(ip);
    if (data + sizeof(*eth) + (ip->ihl * 4) + sizeof(*tcp) > data_end) {
        return XDP_PASS;
    }
    
    // Check if destination port is metadata port
    if (!is_metadata_port(tcp)) {
        return XDP_PASS;
    }
    
    // Check if this is a token request (PUT to /latest/api/token)
    if (is_token_request(tcp, data_end)) {
        // Allow token requests
        log_token_request(ip->saddr);
        return XDP_PASS;
    }
    
    // Block all other metadata requests
    log_blocked_attempt(ip->saddr);
    return XDP_DROP;
}

// eBPF program for TC (Traffic Control) - alternative to XDP
SEC("tc_metadata_blocker")
int tc_metadata_blocker(struct __sk_buff *skb) {
    void *data_end = (void *)(long)skb->data_end;
    void *data = (void *)(long)skb->data;
    
    // Parse Ethernet header
    struct ethhdr *eth = data;
    if (data + sizeof(*eth) > data_end) {
        return TC_ACT_OK;
    }
    
    // Check if this is an IP packet
    if (eth->h_proto != bpf_htons(ETH_P_IP)) {
        return TC_ACT_OK;
    }
    
    // Parse IP header
    struct iphdr *ip = data + sizeof(*eth);
    if (data + sizeof(*eth) + sizeof(*ip) > data_end) {
        return TC_ACT_OK;
    }
    
    // Check if destination is metadata service
    if (!is_metadata_destination(ip)) {
        return TC_ACT_OK;
    }
    
    // Check if this is a TCP packet
    if (!is_tcp(ip)) {
        return TC_ACT_OK;
    }
    
    // Parse TCP header
    struct tcphdr *tcp = get_tcp_header(ip);
    if (data + sizeof(*eth) + (ip->ihl * 4) + sizeof(*tcp) > data_end) {
        return TC_ACT_OK;
    }
    
    // Check if destination port is metadata port
    if (!is_metadata_port(tcp)) {
        return TC_ACT_OK;
    }
    
    // Check if this is a token request (PUT to /latest/api/token)
    if (is_token_request(tcp, data_end)) {
        // Allow token requests
        log_token_request(ip->saddr);
        return TC_ACT_OK;
    }
    
    // Block all other metadata requests
    log_blocked_attempt(ip->saddr);
    return TC_ACT_SHOT;
}

// eBPF program for socket filter (for application-level filtering)
SEC("socket_metadata_filter")
int socket_metadata_filter(struct __sk_buff *skb) {
    void *data_end = (void *)(long)skb->data_end;
    void *data = (void *)(long)skb->data;
    
    // Parse Ethernet header
    struct ethhdr *eth = data;
    if (data + sizeof(*eth) > data_end) {
        return 0;
    }
    
    // Check if this is an IP packet
    if (eth->h_proto != bpf_htons(ETH_P_IP)) {
        return 0;
    }
    
    // Parse IP header
    struct iphdr *ip = data + sizeof(*eth);
    if (data + sizeof(*eth) + sizeof(*ip) > data_end) {
        return 0;
    }
    
    // Check if destination is metadata service
    if (!is_metadata_destination(ip)) {
        return 0;
    }
    
    // Check if this is a TCP packet
    if (!is_tcp(ip)) {
        return 0;
    }
    
    // Parse TCP header
    struct tcphdr *tcp = get_tcp_header(ip);
    if (data + sizeof(*eth) + (ip->ihl * 4) + sizeof(*tcp) > data_end) {
        return 0;
    }
    
    // Check if destination port is metadata port
    if (!is_metadata_port(tcp)) {
        return 0;
    }
    
    // Check if this is a token request (PUT to /latest/api/token)
    if (is_token_request(tcp, data_end)) {
        // Allow token requests
        log_token_request(ip->saddr);
        return 0;
    }
    
    // Block all other metadata requests
    log_blocked_attempt(ip->saddr);
    return -1; // Block the packet
}

char _license[] SEC("license") = "GPL";
