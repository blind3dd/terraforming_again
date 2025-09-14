#!/bin/bash

# Kubernetes Worker Node User Data Script
# This script sets up a Kubernetes worker node

set -e

# Variables
CLUSTER_NAME="${cluster_name}"
CONTROL_PLANE_IP="${control_plane_ip}"

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install kubeadm, kubelet, and kubectl
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Set SELinux in permissive mode
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Install Kubernetes packages
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# Configure kubelet
mkdir -p /etc/kubernetes/kubelet
cat <<EOF | tee /etc/kubernetes/kubelet/kubelet-config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
clusterDomain: cluster.local
clusterDNS:
  - 10.96.0.10
resolvConf: /etc/resolv.conf
runtimeRequestTimeout: 2m
tlsCertFile: /etc/kubernetes/pki/kubelet.crt
tlsPrivateKeyFile: /etc/kubernetes/pki/kubelet.key
EOF

# Wait for control plane to be ready
echo "Waiting for control plane to be ready..."
while ! nc -z $CONTROL_PLANE_IP 6443; do
  echo "Control plane not ready, waiting..."
  sleep 10
done

# Get join command from control plane
# Note: In a real scenario, you would need to securely retrieve the join command
# For now, we'll create a placeholder that needs to be updated
echo "Please run the join command from the control plane node to join this worker to the cluster" > /home/ec2-user/join-instructions.txt
chown ec2-user:ec2-user /home/ec2-user/join-instructions.txt

# Log completion
echo "Kubernetes worker node setup completed successfully" >> /var/log/k8s-setup.log
