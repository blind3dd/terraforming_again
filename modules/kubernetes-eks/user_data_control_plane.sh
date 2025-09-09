#!/bin/bash

# Kubernetes Control Plane User Data Script
# This script sets up a Kubernetes control plane node

set -e

# Variables
CLUSTER_NAME="${cluster_name}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"

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

# Initialize Kubernetes cluster
kubeadm init \
  --pod-network-cidr=$POD_CIDR \
  --service-cidr=$SERVICE_CIDR \
  --cluster-name=$CLUSTER_NAME \
  --apiserver-advertise-address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \
  --apiserver-cert-extra-sans=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
  --node-name=$(hostname)

# Configure kubectl for root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Configure kubectl for ec2-user
mkdir -p /home/ec2-user/.kube
cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Remove taint from master node to allow scheduling
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create a script to join worker nodes
cat <<EOF | tee /home/ec2-user/join-cluster.sh
#!/bin/bash
# This script contains the kubeadm join command for worker nodes
# Run this script on worker nodes to join them to the cluster

$(kubeadm token create --print-join-command)
EOF

chmod +x /home/ec2-user/join-cluster.sh
chown ec2-user:ec2-user /home/ec2-user/join-cluster.sh

# Log completion
echo "Kubernetes control plane setup completed successfully" >> /var/log/k8s-setup.log
