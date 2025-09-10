#!/bin/bash

# Kubernetes Control Plane User Data Script
# This script sets up the Kubernetes control plane on the instance

set -e

# Variables from Terraform
CLUSTER_NAME="${cluster_name}"
CONTROL_PLANE_NAME="${control_plane_name}"
ETCD_IPS="${etcd_ips}"
CONTROL_PLANE_IPS="${control_plane_ips}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
IS_FIRST_CONTROL_PLANE="${is_first_control_plane}"

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Install Kubernetes components
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet

# Configure kubelet
mkdir -p /etc/kubernetes
cat <<EOF | sudo tee /etc/kubernetes/kubelet-config.yaml
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
runtimeRequestTimeout: 2m
hairpinMode: promiscuous-bridge
maxPods: 110
EOF

# Create kubeadm config
cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $(hostname -I | awk '{print $1}')
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  kubeletExtraArgs:
    cloud-provider: aws
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: $(hostname -I | awk '{print $1}'):6443
clusterName: ${CLUSTER_NAME}
networking:
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SERVICE_CIDR}
etcd:
  external:
    endpoints:
$(for ip in $(echo ${ETCD_IPS} | tr ',' ' '); do echo "      - https://${ip}:2379"; done)
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/etcd/etcd-client.crt
    keyFile: /etc/kubernetes/pki/etcd/etcd-client.key
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# Initialize cluster if this is the first control plane
if [ "${IS_FIRST_CONTROL_PLANE}" = "true" ]; then
    # Initialize the cluster
    kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml --upload-certs
    
    # Configure kubectl
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    # Install CNI plugin (Calico)
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
    
    # Wait for nodes to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
else
    # Join as additional control plane node
    # This would need the join command from the first control plane
    echo "Additional control plane node - join command needed"
fi

# Enable kubelet
systemctl start kubelet

# Install additional tools
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Create systemd service for kubelet
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kubelet
KubeletConfigurationFile=/etc/kubernetes/kubelet-config.yaml

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
