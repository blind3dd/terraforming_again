#!/bin/bash

# etcd User Data Script
# This script sets up etcd on the instance

set -e

# Variables from Terraform
CLUSTER_NAME="${cluster_name}"
ETCD_NAME="${etcd_name}"
ETCD_IPS="${etcd_ips}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"

# Update system
yum update -y

# Install etcd
ETCD_VERSION="3.5.9"
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"

tar -xzf etcd-v${ETCD_VERSION}-linux-amd64.tar.gz
sudo mv etcd-v${ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin/

# Create etcd user
sudo useradd --system --home /var/lib/etcd --shell /bin/false etcd

# Create directories
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd

# Create etcd configuration
sudo tee /etc/etcd/etcd.conf <<EOF
ETCD_NAME=${ETCD_NAME}
ETCD_DATA_DIR=/var/lib/etcd
ETCD_LISTEN_PEER_URLS=https://$(hostname -I | awk '{print $1}'):2380
ETCD_LISTEN_CLIENT_URLS=https://$(hostname -I | awk '{print $1}'):2379,https://127.0.0.1:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=https://$(hostname -I | awk '{print $1}'):2380
ETCD_ADVERTISE_CLIENT_URLS=https://$(hostname -I | awk '{print $1}'):2379
ETCD_INITIAL_CLUSTER=${ETCD_IPS}
ETCD_INITIAL_CLUSTER_TOKEN=${CLUSTER_NAME}-etcd-cluster
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_CERT_FILE=/etc/etcd/etcd-server.crt
ETCD_KEY_FILE=/etc/etcd/etcd-server.key
ETCD_PEER_CERT_FILE=/etc/etcd/etcd-peer.crt
ETCD_PEER_KEY_FILE=/etc/etcd/etcd-peer.key
ETCD_TRUSTED_CA_FILE=/etc/etcd/ca.crt
ETCD_PEER_TRUSTED_CA_FILE=/etc/etcd/ca.crt
ETCD_CLIENT_CERT_AUTH=true
ETCD_PEER_CLIENT_CERT_AUTH=true
EOF

# Create systemd service
sudo tee /etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
After=network.target

[Service]
Type=notify
User=etcd
ExecStart=/usr/local/bin/etcd
Restart=on-failure
RestartSec=5s
LimitNOFILE=40000
EnvironmentFile=-/etc/etcd/etcd.conf

[Install]
WantedBy=multi-user.target
EOF

# Enable and start etcd
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# Wait for etcd to be ready
sleep 30

# Verify etcd is running
sudo systemctl status etcd --no-pager
