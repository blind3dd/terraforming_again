# Dual Authentication Setup: SSH + WireGuard VPN

This document explains the **dual authentication** setup that requires both SSH key authentication AND WireGuard VPN connection for accessing instances.

## 🔐 **Dual Authentication Flow**

```
1. Connect to WireGuard VPN (using client keys)
2. SSH to instances (using SSH private key)
3. Access granted only if BOTH conditions are met
```

## 🛡️ **Security Layers**

### **Layer 1: Network ACLs (Network-Level)**
- **SSH access**: ONLY from VPN subnet (`10.100.0.0/24`)
- **WireGuard VPN**: Accessible from anywhere (for initial connection)
- **All other traffic**: Blocked at network level

### **Layer 2: Security Groups (Instance-Level)**
- **SSH access**: ONLY from VPN subnet (`10.100.0.0/24`) and VPC (`172.16.0.0/16`)
- **Kubernetes API**: ONLY from VPN subnet and VPC
- **All other traffic**: Blocked at instance level

### **Layer 3: SSH Key Authentication**
- **SSH private key**: Required for all SSH connections
- **Public key**: Injected into instances via CloudInit
- **Key-based authentication**: Cryptographic key pairs only

### **Layer 4: WireGuard VPN Authentication**
- **Client private key**: Required for VPN connection
- **Server public key**: Required for VPN authentication
- **Key-based authentication**: Cryptographic key pairs only

## 📊 **Network Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Machine │    │  WireGuard VPN  │    │  EC2 Instances  │
│                 │    │                 │    │                 │
│ SSH Private Key │───▶│ Client Config   │───▶│ SSH Public Keys │
│ (ec2-key-pair)  │    │ (No passwords)  │    │ (Injected via   │
│                 │    │                 │    │  CloudInit)     │
│ WireGuard Client│    │ Server Public   │    │                 │
│ (Generated)     │    │ Key (From       │    │                 │
│                 │    │  Deployment)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔑 **Access Requirements**

### **To Access Any Instance:**
1. ✅ **WireGuard VPN connection** (using client keys)
2. ✅ **SSH private key** (ec2-key-pair.pem)
3. ✅ **Source IP from VPN subnet** (10.100.0.0/24)

### **What's Blocked:**
- ❌ **Direct SSH access** from internet
- ❌ **SSH access** from non-VPN IPs
- ❌ **Password authentication**
- ❌ **Certificate-based authentication**
- ❌ **Token-based authentication**

## 🚀 **Access Flow**

### **1. Connect to VPN**
```bash
# Connect to WireGuard VPN
./scripts/vpn-client-setup.sh connect

# Verify VPN connection
./scripts/vpn-client-setup.sh test
```

### **2. SSH to Instances**
```bash
# SSH to jump host (via VPN)
ssh jump-host

# SSH to Kubernetes master (via VPN + jump host)
ssh k8s-master

# SSH to VPN server (via VPN + jump host)
ssh vpn-server
```

### **3. Verify Dual Authentication**
```bash
# Check VPN connection
wg show

# Check SSH connection
ssh -v jump-host

# Verify source IP is from VPN subnet
ssh jump-host "curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
```

## 🔒 **Security Benefits**

### **Network-Level Security:**
- **VPC ACLs**: Block unauthorized traffic at network level
- **Security Groups**: Block unauthorized traffic at instance level
- **VPN-only access**: SSH only from VPN subnet

### **Authentication Security:**
- **Dual authentication**: Both VPN and SSH keys required
- **Key-based authentication**: Cryptographic key pairs only
- **Perfect forward secrecy**: WireGuard key rotation

### **Access Control:**
- **Zero-trust network**: No implicit trust
- **Least privilege**: Minimal required access
- **Audit trail**: All access logged and traceable

## 📋 **Configuration Details**

### **VPC ACLs:**
```hcl
# Private subnet ACL - DUAL AUTHENTICATION
resource "aws_network_acl" "private" {
  # SSH access ONLY from VPN subnet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.100.0.0/24"  # VPN subnet only
    from_port  = 22
    to_port    = 22
  }

  # WireGuard VPN access from anywhere
  ingress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 51820
    to_port    = 51820
  }
}
```

### **Security Groups:**
```hcl
# SSH access from VPN and VPC
ingress {
  description = "SSH from VPN and VPC"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]  # VPC + VPN ranges
}
```

## 🎯 **Use Cases**

### **Remote Development:**
- Connect to VPN → SSH to K8s master → Deploy applications
- All access requires dual authentication

### **Infrastructure Management:**
- Connect to VPN → SSH to jump host → Manage instances
- No direct access from internet

### **Debugging and Monitoring:**
- Connect to VPN → SSH to instances → Access logs and metrics
- Secure access to all infrastructure

## 🚨 **Security Notes**

### **What's Protected:**
- ✅ **SSH connections** encrypted and VPN-only
- ✅ **VPN tunnel** encrypted with perfect forward secrecy
- ✅ **Network traffic** filtered at multiple levels
- ✅ **Authentication** requires both VPN and SSH keys

### **What's NOT Allowed:**
- ❌ **Direct SSH access** from internet
- ❌ **Password authentication**
- ❌ **Certificate-based authentication**
- ❌ **Token-based authentication**
- ❌ **Access from non-VPN IPs**

### **What's Required:**
- ✅ **WireGuard VPN connection** (client cryptographic keys)
- ✅ **SSH private key** (ec2-key-pair.pem)
- ✅ **Source IP from VPN subnet** (10.100.0.0/24)

## 🔄 **Key Rotation**

### **SSH Key Rotation:**
```bash
# 1. Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/ec2-key-pair-new

# 2. Update Terraform with new public key
# 3. Deploy infrastructure with new key
# 4. Replace old private key locally
```

### **WireGuard Key Rotation:**
```bash
# 1. Generate new client keys
./scripts/vpn-client-setup.sh setup

# 2. Update server with new client public key
# 3. Update client config with new keys
```

## 📝 **Summary**

**You have a dual authentication setup:**

- **Network ACLs**: Block SSH access except from VPN subnet
- **Security Groups**: Block SSH access except from VPN subnet
- **SSH Keys**: Required for all SSH connections
- **WireGuard VPN**: Required for network access
- **Key-based authentication**: Cryptographic key pairs only
- **Zero-trust**: No implicit trust, all access verified

This provides **enterprise-grade security** with **dual authentication** requirements for all instance access.
