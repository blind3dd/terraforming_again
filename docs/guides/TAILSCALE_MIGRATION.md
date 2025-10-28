# Tailscale Configuration for Azure+AWS Hybrid Networking

## Overview
Tailscale provides a simpler alternative to WireGuard for hybrid cloud networking with:
- Zero-config VPN mesh
- Built-in authentication and authorization
- Cross-cloud connectivity
- Easy management through web console

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure VM      │    │   AWS EC2       │    │   Local Machine │
│   (Jumphost)     │    │   (Workloads)   │    │   (Developer)   │
│                 │    │                 │    │                 │
│ Tailscale Node  │◄──►│ Tailscale Node  │◄──►│ Tailscale Node  │
│ 10.0.0.1        │    │ 10.0.0.2        │    │ 10.0.0.3        │
│                 │    │                 │    │                 │
│ GSSAPI/Kerberos │    │ Private Subnets │    │ Local Dev        │
│ LDAP Auth       │    │ EKS Clusters    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Benefits over WireGuard

1. **Zero Configuration**: No manual key management
2. **Built-in Auth**: Integrates with Azure AD, Google, GitHub
3. **ACLs**: Fine-grained access control
4. **Monitoring**: Built-in metrics and logging
5. **Cross-Cloud**: Works seamlessly across providers
6. **Subnet Routing**: Automatic subnet advertisement

## Implementation Plan

### 1. Azure Jumphost Setup
- Install Tailscale on Azure VM
- Configure subnet routing for Azure networks
- Enable GSSAPI/Kerberos integration
- Set up LDAP authentication

### 2. AWS Infrastructure Setup
- Install Tailscale on EC2 instances
- Configure subnet routing for AWS VPCs
- Enable EKS cluster access
- Set up private subnet routing

### 3. Developer Access
- Install Tailscale client on local machines
- Configure access to Azure jumphost
- Enable access to AWS workloads
- Set up SSH key forwarding

## Security Considerations

1. **ACLs**: Restrict access by user/group
2. **Subnet Routes**: Only advertise necessary subnets
3. **Exit Nodes**: Control internet egress
4. **SSH**: Use Tailscale for SSH access
5. **Monitoring**: Enable audit logs

## Migration from WireGuard

1. **Phase 1**: Deploy Tailscale alongside WireGuard
2. **Phase 2**: Migrate traffic to Tailscale
3. **Phase 3**: Remove WireGuard configuration
4. **Phase 4**: Clean up WireGuard resources
