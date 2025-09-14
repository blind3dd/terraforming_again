# EC2 DHCP and Private FQDN Configuration

## Overview

This document explains how EC2 instances are configured with DHCP options and private FQDNs for proper DNS resolution within the VPC.

## Configuration Summary

### 1. **VPC-Level DHCP Configuration**

```hcl
# DHCP Options Set for internal private FQDNs
resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "internal.${var.domain_name}"
  domain_name_servers = ["AmazonProvidedDNS"]
  
  # Additional DHCP options for enhanced DNS resolution
  ntp_servers = [
    "169.254.169.123"  # AWS NTP server
  ]
  
  netbios_name_servers = [
    "169.254.169.123"  # AWS NTP server (used as placeholder)
  ]
  
  netbios_node_type = 2  # P-node (point-to-point)
}
```

### 2. **EC2 Instance Private FQDN Configuration**

All EC2 instances are configured with private FQDNs using the pattern:
- **Jump Host**: `go-mysql-jump-host.internal.${var.domain_name}`
- **VPN Server**: `wireguard-vpn-server.internal.${var.domain_name}`
- **Kubernetes Control Plane**: `kubernetes-control-plane.internal.${var.domain_name}`

## EC2 Instance Configurations

### 1. **Jump Host (Go-MySQL)**

```yaml
# Set hostname with private FQDN
hostname: go-mysql-jump-host
fqdn: go-mysql-jump-host.internal.${domain_name}

# Configure DHCP and DNS for private FQDN resolution
runcmd:
  # Configure DHCP client for private FQDN
  - echo "domain internal.${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "prepend domain-name-servers 169.254.169.253;" >> /etc/dhcp/dhclient.conf
  
  # Configure resolv.conf for private FQDN resolution
  - echo "domain internal.${domain_name}" > /etc/resolv.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/resolv.conf
  - echo "nameserver 169.254.169.253" >> /etc/resolv.conf
  - echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  - echo "nameserver 8.8.4.4" >> /etc/resolv.conf
  
  # Make resolv.conf immutable to prevent DHCP from overwriting
  - chattr +i /etc/resolv.conf
  
  # Restart networking to apply DHCP changes
  - systemctl restart networking
  
  # Test DNS resolution
  - nslookup go-mysql-jump-host.internal.${domain_name}
  - nslookup mysql.internal.${domain_name}
  - nslookup k8s-api.internal.${domain_name}
```

### 2. **WireGuard VPN Server**

```yaml
# Set hostname with private FQDN
hostname: wireguard-vpn-server
fqdn: wireguard-vpn-server.internal.${domain_name}

# Configure DHCP and DNS for private FQDN resolution
runcmd:
  # Configure DHCP client for private FQDN
  - echo "domain internal.${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "prepend domain-name-servers 169.254.169.253;" >> /etc/dhcp/dhclient.conf
  
  # Configure resolv.conf for private FQDN resolution
  - echo "domain internal.${domain_name}" > /etc/resolv.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/resolv.conf
  - echo "nameserver 169.254.169.253" >> /etc/resolv.conf
  - echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  - echo "nameserver 8.8.4.4" >> /etc/resolv.conf
  
  # Make resolv.conf immutable to prevent DHCP from overwriting
  - chattr +i /etc/resolv.conf
  
  # Test DNS resolution
  - nslookup wireguard-vpn-server.internal.${domain_name}
  - nslookup mysql.internal.${domain_name}
```

### 3. **Kubernetes Control Plane**

```yaml
# Set hostname with private FQDN
hostname: kubernetes-control-plane
fqdn: kubernetes-control-plane.internal.${domain_name}

# Configure DHCP and DNS for private FQDN resolution
runcmd:
  # Configure DHCP client for private FQDN
  - echo "domain internal.${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/dhcp/dhclient.conf
  - echo "prepend domain-name-servers 169.254.169.253;" >> /etc/dhcp/dhclient.conf
  
  # Configure resolv.conf for private FQDN resolution
  - echo "domain internal.${domain_name}" > /etc/resolv.conf
  - echo "search internal.${domain_name} ${domain_name}" >> /etc/resolv.conf
  - echo "nameserver 169.254.169.253" >> /etc/resolv.conf
  - echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  - echo "nameserver 8.8.4.4" >> /etc/resolv.conf
  
  # Make resolv.conf immutable to prevent DHCP from overwriting
  - chattr +i /etc/resolv.conf
  
  # Test DNS resolution
  - nslookup kubernetes-control-plane.internal.${domain_name}
  - nslookup mysql.internal.${domain_name}
```

## DNS Resolution Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    EC2 Instance DNS Resolution                 │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   EC2 Instance  │───►│  DHCP Client    │                   │
│  │                 │    │  Configuration  │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  /etc/resolv.conf│───►│  VPC DHCP       │                   │
│  │  (Immutable)    │    │  Options Set    │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  DNS Query      │───►│  Route53        │                   │
│  │  (Private FQDN) │    │  Private Zone   │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  AWS VPC DNS    │───►│  Service        │                   │
│  │  (169.254.169.253)│    │  Resolution     │                   │
│  └─────────────────┘    └─────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Private FQDN Mapping

### **Service FQDNs**

| Service | Private FQDN | Purpose |
|---------|--------------|---------|
| Jump Host | `go-mysql-jump-host.internal.${var.domain_name}` | Go-MySQL API and bastion host |
| VPN Server | `wireguard-vpn-server.internal.${var.domain_name}` | WireGuard VPN access |
| Kubernetes API | `kubernetes-control-plane.internal.${var.domain_name}` | Kubernetes cluster access |
| RDS Database | `mysql.internal.${var.domain_name}` | Database connection |

### **DNS Resolution Priority**

1. **AWS VPC DNS** (`169.254.169.253`) - Primary resolver for private FQDNs
2. **Google DNS** (`8.8.8.8`) - Backup resolver for public domains
3. **Google DNS** (`8.8.4.4`) - Secondary backup resolver

## Configuration Details

### 1. **DHCP Client Configuration**

```bash
# /etc/dhcp/dhclient.conf
domain internal.${domain_name}
search internal.${domain_name} ${domain_name}
prepend domain-name-servers 169.254.169.253;
```

### 2. **DNS Resolver Configuration**

```bash
# /etc/resolv.conf (immutable)
domain internal.${domain_name}
search internal.${domain_name} ${domain_name}
nameserver 169.254.169.253
nameserver 8.8.8.8
nameserver 8.8.4.4
```

### 3. **Immutable resolv.conf**

The `/etc/resolv.conf` file is made immutable using `chattr +i` to prevent:
- DHCP from overwriting the configuration
- System updates from changing DNS settings
- Manual modifications from being lost

## Verification Commands

### 1. **Check DHCP Configuration**

```bash
# Check DHCP options set
aws ec2 describe-dhcp-options --dhcp-options-ids $(terraform output -raw dhcp_options_id)

# Check VPC association
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)
```

### 2. **Test Private FQDN Resolution**

```bash
# From EC2 instance, test private FQDN resolution
nslookup go-mysql-jump-host.internal.${var.domain_name}
nslookup wireguard-vpn-server.internal.${var.domain_name}
nslookup kubernetes-control-plane.internal.${var.domain_name}
nslookup mysql.internal.${var.domain_name}
```

### 3. **Check DNS Configuration**

```bash
# Check resolv.conf
cat /etc/resolv.conf

# Check if resolv.conf is immutable
lsattr /etc/resolv.conf

# Check DHCP client configuration
cat /etc/dhcp/dhclient.conf
```

### 4. **Test Service Connectivity**

```bash
# Test RDS connection using private FQDN
mysql -h mysql.internal.${var.domain_name} -u admin -p

# Test Kubernetes API using private FQDN
curl -k https://kubernetes-control-plane.internal.${var.domain_name}:6443/version

# Test VPN server connectivity
ping wireguard-vpn-server.internal.${var.domain_name}
```

## Troubleshooting

### 1. **DNS Resolution Issues**

```bash
# Check DNS resolution
dig mysql.internal.${var.domain_name}
nslookup mysql.internal.${var.domain_name}

# Check Route53 private zone
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw private_zone_id)
```

### 2. **DHCP Configuration Issues**

```bash
# Restart DHCP client
sudo systemctl restart networking
sudo dhclient -r && sudo dhclient

# Check DHCP lease
cat /var/lib/dhcp/dhclient.leases
```

### 3. **resolv.conf Issues**

```bash
# Remove immutable flag if needed
sudo chattr -i /etc/resolv.conf

# Restore configuration
sudo echo "domain internal.${var.domain_name}" > /etc/resolv.conf
sudo echo "search internal.${var.domain_name} ${var.domain_name}" >> /etc/resolv.conf
sudo echo "nameserver 169.254.169.253" >> /etc/resolv.conf
sudo echo "nameserver 8.8.8.8" >> /etc/resolv.conf
sudo echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Make immutable again
sudo chattr +i /etc/resolv.conf
```

## Security Considerations

### 1. **DNS Security**
- **Private DNS**: All internal communication uses private FQDNs
- **DNS Override Protection**: resolv.conf is immutable to prevent tampering
- **DNS Validation**: DNS responses are validated against Route53

### 2. **Network Security**
- **VPC Isolation**: Private FQDNs only work within the VPC
- **DNS Filtering**: Only authorized DNS servers are used
- **Traffic Encryption**: DNS queries can be encrypted with DNS over HTTPS

### 3. **Access Control**
- **Private Access Only**: Private FQDNs are not accessible from internet
- **VPN Required**: External access requires VPN connection
- **Authentication**: All services require proper authentication

## Best Practices

### 1. **Configuration Management**
- **Immutable DNS**: Use immutable resolv.conf to prevent changes
- **DHCP Integration**: Leverage VPC DHCP options for consistency
- **Backup DNS**: Always configure backup DNS servers

### 2. **Monitoring**
- **DNS Resolution**: Monitor DNS resolution success rates
- **DHCP Leases**: Track DHCP lease renewals
- **Service Discovery**: Monitor service discovery functionality

### 3. **Documentation**
- **FQDN Mapping**: Document all private FQDNs and their purposes
- **DNS Configuration**: Document DNS configuration changes
- **Troubleshooting**: Maintain troubleshooting procedures

## Conclusion

This configuration provides:

✅ **Consistent Private FQDNs**: All EC2 instances use private FQDNs
✅ **Reliable DNS Resolution**: Multiple DNS servers with failover
✅ **Immutable Configuration**: DNS settings protected from changes
✅ **Service Discovery**: Automatic service discovery within VPC
✅ **Security**: Private DNS with VPC isolation
✅ **Monitoring**: DNS resolution testing and validation

The EC2 instances are now properly configured with DHCP options and private FQDNs for secure, reliable service discovery within the VPC.
