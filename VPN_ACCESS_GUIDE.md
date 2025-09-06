# WireGuard VPN Access Guide

This guide explains how to set up and use the WireGuard VPN client to securely access your infrastructure.

## 🔐 **Access Flow**

```
Local Machine → WireGuard VPN → Jump Host → Target Instances
```

## 📋 **Prerequisites**

1. **VPN Server Deployed**: The WireGuard VPN server must be running in your infrastructure
2. **Server Keys**: You need the VPN server's public key and endpoint
3. **WireGuard Client**: Install WireGuard on your local machine

## 🚀 **Quick Setup**

### 1. Install WireGuard Client

**macOS:**
```bash
# Via Homebrew
brew install wireguard-tools

# Or download from Mac App Store
# Search for "WireGuard" and install
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install wireguard

# CentOS/RHEL
sudo yum install epel-release && sudo yum install wireguard-tools

# Fedora
sudo dnf install wireguard-tools
```

**Windows:**
- Download from [WireGuard.com](https://www.wireguard.com/install/)
- Install the Windows client

### 2. Setup VPN Client

```bash
# Make script executable
chmod +x scripts/vpn-client-setup.sh

# Setup VPN client
./scripts/vpn-client-setup.sh setup
```

Follow the prompts to enter:
- VPN server public key
- VPN server endpoint (public IP or domain)

### 3. Connect to VPN

```bash
# Connect to VPN
./scripts/vpn-client-setup.sh connect

# Test connection
./scripts/vpn-client-setup.sh test

# Check status
./scripts/vpn-client-setup.sh status
```

## 🔧 **Manual Setup (Alternative)**

### 1. Generate Client Keys

```bash
# Generate private key
wg genkey > client_private.key

# Generate public key
wg pubkey < client_private.key > client_public.key

# Show public key (needed for server configuration)
cat client_public.key
```

### 2. Create Client Configuration

Create `~/.wireguard/secure-infrastructure.conf`:

```ini
[Interface]
PrivateKey = YOUR_CLIENT_PRIVATE_KEY
Address = 10.100.0.2/24
DNS = 8.8.8.8, 1.1.1.1
MTU = 1420

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = VPN_SERVER_IP:51820
AllowedIPs = 10.100.0.0/24, 172.16.0.0/16
PersistentKeepalive = 25
```

### 3. Connect to VPN

```bash
# Connect
sudo wg-quick up ~/.wireguard/secure-infrastructure.conf

# Disconnect
sudo wg-quick down ~/.wireguard/secure-infrastructure.conf

# Check status
wg show
```

## 🖥️ **macOS GUI Setup**

### 1. Install WireGuard App

- Download from Mac App Store
- Or download from [WireGuard.com](https://www.wireguard.com/install/)

### 2. Import Configuration

1. Open WireGuard app
2. Click "Add Tunnel" → "Create from file..."
3. Select the `.mobileconfig` file from `templates/`
4. Update the placeholders with actual values

### 3. Connect

1. Click the tunnel name
2. Click "Activate"
3. Enter your password when prompted

## 🔑 **SSH Access After VPN Connection**

Once connected to VPN, you can access instances:

```bash
# Setup SSH config
cp templates/ssh-config-template ~/.ssh/config

# Connect to jump host
ssh jump-host

# Connect to Kubernetes master
ssh k8s-master
ssh kubernetes

# Connect to VPN server
ssh vpn-server
ssh wireguard
```

## 🛠️ **Troubleshooting**

### VPN Connection Issues

```bash
# Check VPN status
./scripts/vpn-client-setup.sh status

# Test connectivity
ping 10.100.0.1  # VPN server
ping 172.16.2.10  # Jump host

# Check WireGuard logs
sudo journalctl -u wg-quick@secure-infrastructure
```

### SSH Connection Issues

```bash
# Test SSH connectivity
ssh -v jump-host

# Check SSH config
ssh -F ~/.ssh/config -v jump-host

# Test direct connection
ssh -o ProxyJump=jump-host k8s-master
```

### Common Issues

1. **VPN won't connect**: Check server public key and endpoint
2. **SSH connection refused**: Ensure VPN is connected first
3. **Permission denied**: Check SSH key permissions (600)
4. **Host key verification failed**: Use `-o StrictHostKeyChecking=no` for first connection

## 🔒 **Security Features**

- **Strong Encryption**: ChaCha20-Poly1305
- **Perfect Forward Secrecy**: New keys for each session
- **Zero-Knowledge**: No logging of traffic content
- **eBPF Security**: Kernel-level network filtering
- **IMDSv2 Enforcement**: Blocks direct metadata access
- **Static IPs**: Predictable access patterns

## 📊 **Network Topology**

```
Internet
    │
    ▼
┌─────────────────┐
│   VPN Server    │
│ 172.16.2.11:51820│
└─────────────────┘
    │
    ▼
┌─────────────────┐
│   Jump Host     │
│   172.16.2.10   │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  K8s Master     │
│   172.16.2.12   │
└─────────────────┘
```

## 🎯 **Use Cases**

1. **Remote Development**: Access Kubernetes cluster from anywhere
2. **Infrastructure Management**: Manage servers securely
3. **Debugging**: Troubleshoot issues remotely
4. **Monitoring**: Access monitoring tools and logs
5. **Backup**: Secure access for backup operations

## 📝 **Notes**

- VPN connection is required before SSH access
- All traffic is encrypted through the VPN tunnel
- Static private IPs ensure predictable access
- IMDSv2 enforcement prevents metadata leaks
- eBPF provides kernel-level security

## 🆘 **Support**

If you encounter issues:

1. Check the troubleshooting section above
2. Verify VPN server is running and accessible
3. Ensure correct keys and endpoints
4. Check firewall rules and security groups
5. Review logs for error messages
