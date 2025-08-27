#!/bin/bash
# Kubernetes Control Plane Setup Script
# This script initializes the Kubernetes cluster and installs Calico CNI

set -e

# Configuration variables
ENVIRONMENT="${environment}"
SERVICE_NAME="${service_name}"
CLUSTER_NAME="${cluster_name}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
CALICO_VERSION="${calico_version}"
KUBERNETES_VERSION="${kubernetes_version}"
AWS_REGION="${aws_region}"
AWS_ACCOUNT_ID="${aws_account_id}"
RDS_ENDPOINT="${rds_endpoint}"
RDS_PORT="${rds_port}"
RDS_DATABASE="${rds_database}"
RDS_USERNAME="${rds_username}"
RDS_PASSWORD_PARAMETER="${rds_password_parameter}"

# AWS credentials for cert-manager Route53 integration
AWS_ACCESS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
ROUTE53_ZONE_ID="${route53_zone_id}"

# Feature flags for control plane configuration
ENABLE_MULTICLUSTER_HEADLESS="${enable_multicluster_headless:-false}"
ENABLE_NATIVE_SIDECARS="${enable_native_sidecars:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Function to check if this is the first control plane node
is_first_control_plane() {
    local instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    local private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    
    # Check if etcd data directory is empty (first node)
    if [ ! -d "/var/lib/etcd/member" ] || [ -z "$(ls -A /var/lib/etcd/member 2>/dev/null)" ]; then
        log "This appears to be the first control plane node"
        return 0
    else
        log "This appears to be a subsequent control plane node"
        return 1
    fi
}

# Function to get database password from SSM
get_db_password() {
    log "Retrieving database password from SSM Parameter Store..."
    local password
    password=$(aws ssm get-parameter --name "$RDS_PASSWORD_PARAMETER" --with-decryption --region "$AWS_REGION" --query 'Parameter.Value' --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$password" ]; then
        echo "$password"
        log "Successfully retrieved database password"
    else
        error "Failed to retrieve database password from SSM"
    fi
}

# Function to test database connectivity
test_database_connection() {
    log "Testing database connectivity..."
    local password=$(get_db_password)
    
    # Install MySQL client if not present
    if ! command -v mysql &> /dev/null; then
        log "Installing MySQL client..."
        sudo yum install -y mysql
    fi
    
    # Test connection
    if mysql -h "$RDS_ENDPOINT" -P "$RDS_PORT" -u "$RDS_USERNAME" -p"$password" -e "SELECT 1;" 2>/dev/null; then
        log "✅ Database connection successful"
    else
        warn "⚠️  Database connection failed - this is expected if RDS is not yet available"
    fi
}

# Function to initialize the first control plane node
init_first_control_plane() {
    log "Initializing first control plane node..."
    
    # Create kubeadm config
    cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    cgroup-driver: "systemd"
    container-runtime-endpoint: "unix:///run/containerd/containerd.sock"
    node-ip: "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
    cloud-provider: "aws"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "$KUBERNETES_VERSION"
clusterName: "$CLUSTER_NAME"
controlPlaneEndpoint: "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443"
networking:
  podSubnet: "$POD_CIDR"
  serviceSubnet: "$SERVICE_CIDR"
  dnsDomain: "cluster.local"
       apiServer:
         certSANs:
           # Node IPs
           - "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
           - "$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
           # Kubernetes service names
           - "kubernetes.default.svc"
           - "kubernetes.default.svc.cluster.local"
           - "kubernetes"
           # Localhost addresses
           - "127.0.0.1"
           - "localhost"
           - "::1"
           # Load balancer endpoint (if using ALB)
           - "${kubernetes_api_endpoint}"
           - "*.${kubernetes_api_endpoint}"
           # Cluster internal addresses
           - "*.cluster.local"
           - "*.${CLUSTER_NAME}.cluster.local"
           # AWS metadata
           - "$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
           # Additional SANs for certificate rotation
           - "*.kube-system.svc.cluster.local"
           - "*.default.svc.cluster.local"
           - "*.go-mysql-api.svc.cluster.local"
  extraArgs:
    cloud-provider: "aws"
    cloud-config: "/etc/kubernetes/cloud-config"
    # Proxy certs for CRDs
    proxy-client-cert-file: "/etc/kubernetes/pki/front-proxy-client.crt"
    proxy-client-key-file: "/etc/kubernetes/pki/front-proxy-client.key"
    requestheader-client-ca-file: "/etc/kubernetes/pki/front-proxy-ca.crt"
    requestheader-allowed-names: "front-proxy-client"
    requestheader-extra-headers-prefix: "X-Remote-Extra-"
    requestheader-group-headers: "X-Remote-Group"
    requestheader-username-headers: "X-Remote-User"
controllerManager:
  extraArgs:
    cloud-provider: "aws"
    cloud-config: "/etc/kubernetes/cloud-config"
    allocate-node-cidrs: "false"
    # Proxy certs for CRDs
    use-service-account-credentials: "true"
    service-account-private-key-file: "/etc/kubernetes/pki/sa.key"
    root-ca-file: "/etc/kubernetes/pki/ca.crt"
    # gRPC certs for etcd connectivity
    etcd-cafile: "/etc/kubernetes/pki/etcd/ca.crt"
    etcd-certfile: "/etc/kubernetes/pki/etcd/client.crt"
    etcd-keyfile: "/etc/kubernetes/pki/etcd/client.key"
scheduler:
  extraArgs: {}
etcd:
  local:
    dataDir: "/var/lib/etcd"
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2379"
      advertise-client-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2379"
      listen-peer-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-advertise-peer-urls: "https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-cluster: "$(hostname)=https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):2380"
      initial-cluster-state: "new"
      initial-cluster-token: "etcd-cluster"
      client-cert-auth: "true"
      peer-cert-auth: "true"
      cert-file: "/etc/kubernetes/pki/etcd/server.crt"
      key-file: "/etc/kubernetes/pki/etcd/server.key"
      peer-cert-file: "/etc/kubernetes/pki/etcd/peer.crt"
      peer-key-file: "/etc/kubernetes/pki/etcd/peer.key"
      trusted-ca-file: "/etc/kubernetes/pki/etcd/ca.crt"
      peer-trusted-ca-file: "/etc/kubernetes/pki/etcd/ca.crt"
      # gRPC specific settings
      grpc-keepalive-time: "2s"
      grpc-keepalive-timeout: "6s"
      grpc-keepalive-min-time: "1s"
      grpc-max-recv-msg-size: "16777216"
      grpc-max-send-msg-size: "16777216"
EOF

    # Initialize the cluster
    log "Running kubeadm init..."
    sudo kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs
    
    # Set up kubectl for ec2-user
    log "Setting up kubectl configuration..."
    mkdir -p /home/ec2-user/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
    sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config
    
    # Also copy to root for system operations
    sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
    
    # Verify proxy certificates are generated
    log "Verifying proxy certificates for CRDs..."
    if [ -f "/etc/kubernetes/pki/front-proxy-ca.crt" ] && [ -f "/etc/kubernetes/pki/front-proxy-client.crt" ] && [ -f "/etc/kubernetes/pki/front-proxy-client.key" ]; then
        log "✅ Proxy certificates generated successfully"
    else
        error "❌ Proxy certificates not found - CRD functionality may be limited"
    fi
    
    # Install Calico CNI
    install_calico
    
    # Create join command file for other nodes
    log "Creating join command for other nodes..."
    kubeadm token create --print-join-command > /home/ec2-user/join-command.txt
    sudo kubeadm init phase upload-certs --upload-certs > /home/ec2-user/upload-certs.txt
    
    # Create control plane join command
    cat > /home/ec2-user/control-plane-join-command.txt <<EOF
# Control Plane Join Command
# Run this on additional control plane nodes:
$(kubeadm token create --print-join-command) --control-plane --certificate-key $(sudo kubeadm init phase upload-certs --upload-certs | tail -n 1)
EOF
    
    chown ec2-user:ec2-user /home/ec2-user/*.txt
    
    log "✅ First control plane node initialized successfully"
}

# Function to join as additional control plane node
join_control_plane() {
    log "Joining as additional control plane node..."
    
    # Wait for the first control plane node to be ready
    log "Waiting for first control plane node to be ready..."
    sleep 30
    
    # For now, we'll create a placeholder join command
    # In a real scenario, you'd get this from the first control plane node
    cat > /home/ec2-user/join-command.txt <<EOF
# Additional Control Plane Join Command
# This would be obtained from the first control plane node
# Example: kubeadm join <first-control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash> --control-plane --certificate-key <key>
EOF
    
    chown ec2-user:ec2-user /home/ec2-user/join-command.txt
    
    warn "⚠️  Manual intervention required to join additional control plane nodes"
    warn "   Please run the join command from the first control plane node"
}

# Function to install Calico CNI
install_calico() {
    log "Installing Calico CNI..."
    
    # Create Calico namespace
    kubectl create namespace calico-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Calico operator
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/tigera-operator.yaml
    
    # Wait for operator to be ready
    log "Waiting for Calico operator to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/tigera-operator -n tigera-operator
    
    # Create Calico custom resources
    cat > /tmp/calico-custom-resources.yaml <<EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  cni:
    type: Calico
    ipPools:
    - blockSize: 26
      cidr: ${POD_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  # The default IP pool configuration for your cluster.
  ipPools:
  - blockSize: 26
    cidr: ${POD_CIDR}
    encapsulation: VXLANCrossSubnet
    natOutgoing: Enabled
    nodeSelector: all()
  # Configures Calico CNI plugin for Kubernetes.
  kubernetesProvider: EKS
  # CNI configuration for the cluster.
  cni:
    type: Calico
    ipPools:
    - blockSize: 26
      cidr: ${POD_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
---
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  cni:
    type: Calico
    ipPools:
    - blockSize: 26
      cidr: ${POD_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  # The default IP pool configuration for your cluster.
  ipPools:
  - blockSize: 26
    cidr: ${POD_CIDR}
    encapsulation: VXLANCrossSubnet
    natOutgoing: Enabled
    nodeSelector: all()
  # Configures Calico CNI plugin for Kubernetes.
  kubernetesProvider: EKS
EOF
    
    kubectl create -f /tmp/calico-custom-resources.yaml
    
    # Wait for Calico to be ready
    log "Waiting for Calico to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/calico-kube-controllers -n kube-system
    kubectl wait --for=condition=ready --timeout=300s pods -l k8s-app=calico-node -n kube-system
    
    # Verify Calico installation
    log "Verifying Calico installation..."
    kubectl get pods -n calico-system
    kubectl get pods -n kube-system -l k8s-app=calico-node
    
    log "✅ Calico CNI installed successfully"
}

# Function to install cert-manager
install_cert_manager() {
    log "Installing cert-manager..."
    
    # Install cert-manager CRDs
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
    
    # Add cert-manager Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Install cert-manager
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.13.3 \
        --set installCRDs=true \
        --set global.leaderElection.namespace=cert-manager \
        --set global.leaderElection.leaseDuration=60s \
        --set global.leaderElection.renewDeadline=40s \
        --set global.leaderElection.retryPeriod=15s \
        --set replicaCount=1 \
        --set resources.requests.cpu=100m \
        --set resources.requests.memory=128Mi \
        --set resources.limits.cpu=200m \
        --set resources.limits.memory=256Mi
    
    # Wait for cert-manager to be ready
    log "Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
    
    # Create ClusterIssuer for Let's Encrypt
    cat > /tmp/cluster-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@${ENVIRONMENT}-${SERVICE_NAME}.local
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
    - dns01:
        route53:
          region: ${AWS_REGION}
          hostedZoneID: ${ROUTE53_ZONE_ID}
          accessKeyID: ${AWS_ACCESS_KEY_ID}
          secretAccessKeySecretRef:
            name: cert-manager-route53-credentials
            key: secret-access-key
EOF
    
    kubectl apply -f /tmp/cluster-issuer.yaml
    
    # Create secret for Route53 credentials (if using DNS01 challenge)
    kubectl create secret generic cert-manager-route53-credentials \
        --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
        --namespace cert-manager \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log "✅ cert-manager installed successfully"
}

# Function to configure CoreDNS with proper Corefile
configure_coredns() {
    log "Configuring CoreDNS with proper Corefile..."
    
    # Wait for CoreDNS to be ready
    log "Waiting for CoreDNS to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/coredns -n kube-system
    
    # Create comprehensive CoreDNS configuration
    cat > /tmp/coredns-configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  Corefile: |
    # Global configuration for all zones
    .:53 {
        # Error handling
        errors
        
        # Health check endpoint
        health {
           lameduck 5s
        }
        
        # Ready endpoint for readiness probe
        ready
        
        # Kubernetes service discovery
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
           # Enable DNS-based service discovery
           dns.kubernetes.io/fallthrough in-addr.arpa ip6.arpa
        }
        
        # Prometheus metrics
        prometheus :9153
        
        # Forward external queries to upstream DNS servers
        forward . 8.8.8.8 8.8.4.4 1.1.1.1 {
           max_concurrent 1000
           # Use TCP for large queries
           force_tcp
           # Health check upstream servers
           health_check 5s
        }
        
        # Cache responses
        cache 30
        
        # Prevent infinite loops
        loop
        
        # Reload configuration on changes
        reload
        
        # Load balancing for multiple upstream servers
        loadbalance
        
        # Log all queries
        log {
           class all
        }
        
        # Hosts file for local overrides
        hosts {
           fallthrough
        }
    }
    
    # Internal cluster domain - downstream DNS
    cluster.local:53 {
        errors
        cache 30
        reload
        loop
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        # Forward to upstream for external lookups
        forward . 8.8.8.8 8.8.4.4
        loadbalance
    }
    
    # Reverse DNS for IPv4 - downstream DNS
    in-addr.arpa:53 {
        errors
        cache 30
        reload
        loop
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        # Forward to upstream for external lookups
        forward . 8.8.8.8 8.8.4.4
        loadbalance
    }
    
    # Reverse DNS for IPv6 - downstream DNS
    ip6.arpa:53 {
        errors
        cache 30
        reload
        loop
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        # Forward to upstream for external lookups
        forward . 8.8.8.8 8.8.4.4
        loadbalance
    }
    
    # External service discovery - upstream DNS
    .:53 {
        errors
        cache 30
        reload
        loop
        # Multiple upstream DNS servers for redundancy
        forward . 8.8.8.8 8.8.4.4 1.1.1.1 {
           max_concurrent 1000
           force_tcp
           health_check 5s
        }
        loadbalance
    }
EOF
    
    kubectl apply -f /tmp/coredns-configmap.yaml
    
    # Create CoreDNS deployment with proper resources
    cat > /tmp/coredns-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9153"
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: coredns
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Exists"
          effect: "NoSchedule"
      nodeSelector:
        kubernetes.io/os: linux
      containers:
      - name: coredns
        image: registry.k8s.io/coredns/coredns:v1.11.1
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
            cpu: 100m
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
      dnsPolicy: Default
      volumes:
      - name: config-volume
        configMap:
          name: coredns
          items:
          - key: Corefile
            path: Corefile
EOF
    
    kubectl apply -f /tmp/coredns-deployment.yaml
    
    # Create CoreDNS service
    cat > /tmp/coredns-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.96.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
    protocol: TCP
EOF
    
    kubectl apply -f /tmp/coredns-service.yaml
    
    # Create CoreDNS service account
    cat > /tmp/coredns-serviceaccount.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
EOF
    
    kubectl apply -f /tmp/coredns-serviceaccount.yaml
    
    # Create CoreDNS RBAC
    cat > /tmp/coredns-rbac.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:coredns
rules:
- apiGroups: [""]
  resources: ["endpoints", "services", "pods", "namespaces"]
  verbs: ["list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
EOF
    
    kubectl apply -f /tmp/coredns-rbac.yaml
    
    # Restart CoreDNS to apply new configuration
    kubectl rollout restart deployment/coredns -n kube-system
    
    # Wait for CoreDNS to be ready after restart
    kubectl wait --for=condition=available --timeout=300s deployment/coredns -n kube-system
    
    # Test DNS resolution
    log "Testing DNS resolution..."
    kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local || warn "DNS test failed"
    
    # Test external DNS resolution
    log "Testing external DNS resolution..."
    kubectl run dns-external-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup google.com || warn "External DNS test failed"
    
    log "✅ CoreDNS configured successfully with comprehensive Corefile"
}

# Function to install Istio in Ambient Mode
install_istio() {
    log "Installing Istio in Ambient Mode..."
    
    # Download Istio
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
    cd istio-1.20.0
    export PATH=$PWD/bin:$PATH
    
    # Install Istio in Ambient Mode with feature flags
    cat > /tmp/istio-ambient-config.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 500m
            memory: 2048Mi
          limits:
            cpu: 1000m
            memory: 4096Mi
        hpaSpec:
          maxReplicas: 5
          minReplicas: 1
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        hpaSpec:
          maxReplicas: 5
          minReplicas: 1
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
    ztunnel:
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
  values:
    global:
      proxy:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      # Configure outbound traffic policy with RDS access
      outboundTrafficPolicy:
        mode: REGISTRY_ONLY
      # Configure proxy settings for external access
      proxy:
        includeIPRanges: "10.244.0.0/16,10.96.0.0/12"
        excludeIPRanges: "${RDS_ENDPOINT}/32"
      logging:
        level: "default:info"
      # Native sidecars feature flag
      nativeSidecar: ${ENABLE_NATIVE_SIDECARS}
    pilot:
      autoscaleEnabled: true
      autoscaleMin: 1
      autoscaleMax: 5
      resources:
        requests:
          cpu: 500m
          memory: 2048Mi
        limits:
          cpu: 1000m
          memory: 4096Mi
    gateways:
      istio-ingressgateway:
        autoscaleEnabled: true
        autoscaleMin: 1
        autoscaleMax: 5
      istio-egressgateway:
        autoscaleEnabled: true
        autoscaleMin: 1
        autoscaleMax: 5
    ztunnel:
      autoscaleEnabled: true
      autoscaleMin: 1
      autoscaleMax: 5
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
    kiali:
      enabled: true
      dashboard:
        auth:
          strategy: token
    grafana:
      enabled: true
      security:
        enabled: true
    tracing:
      enabled: true
      provider: jaeger
EOF
    
    # Install Istio in Ambient Mode
    istioctl install -f /tmp/istio-ambient-config.yaml --set values.global.outboundTrafficPolicy.mode=REGISTRY_ONLY -y
    
    # Wait for Istio to be ready
    log "Waiting for Istio Ambient Mode to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
    kubectl wait --for=condition=available --timeout=300s deployment/istio-ingressgateway -n istio-system
    kubectl wait --for=condition=available --timeout=300s deployment/istio-egressgateway -n istio-system
    kubectl wait --for=condition=available --timeout=300s daemonset/ztunnel -n istio-system
    
    # Enable Ambient Mode for default namespace
    kubectl label namespace default istio.io/dataplane-mode=ambient
    
    # Create Istio Gateway for external access
    cat > /tmp/istio-gateway.yaml <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: go-mysql-api-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: go-mysql-api-tls
    hosts:
    - "*"
EOF
    
    kubectl apply -f /tmp/istio-gateway.yaml
    
    # Create Headless Service for Go MySQL API (for Ambient Mode) - conditional based on feature flag
    if [ "$ENABLE_MULTICLUSTER_HEADLESS" = "true" ]; then
        log "Creating headless service for multicluster support..."
        cat > /tmp/go-mysql-api-headless-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: go-mysql-api-headless
  namespace: go-mysql-api
  labels:
    app: go-mysql-api
    service: headless
    multicluster: "true"
  annotations:
    # Enable Ambient Mode for this service
    istio.io/dataplane-mode: "ambient"
    # Multicluster headless service annotations
    service.kubernetes.io/headless: "true"
    multicluster.kubernetes.io/service-name: "go-mysql-api"
    multicluster.kubernetes.io/cluster-id: "${CLUSTER_NAME}"
spec:
  type: ClusterIP
  clusterIP: None  # This makes it headless
  selector:
    app: go-mysql-api
  ports:
  - name: http
    port: 8088
    targetPort: 8088
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP
  - name: health
    port: 8080
    targetPort: 8080
    protocol: TCP
  # Additional ports for multicluster communication
  - name: grpc
    port: 9091
    targetPort: 9091
    protocol: TCP
  - name: admin
    port: 9092
    targetPort: 9092
    protocol: TCP
EOF
        
        kubectl apply -f /tmp/go-mysql-api-headless-service.yaml
        
        # Create multicluster service export
        cat > /tmp/multicluster-service-export.yaml <<EOF
apiVersion: multicluster.x-k8s.io/v1alpha1
kind: ServiceExport
metadata:
  name: go-mysql-api-headless
  namespace: go-mysql-api
spec:
  ports:
  - name: http
    port: 8088
    protocol: TCP
  - name: metrics
    port: 9090
    protocol: TCP
  - name: health
    port: 8080
    protocol: TCP
  - name: grpc
    port: 9091
    protocol: TCP
EOF
        
        kubectl apply -f /tmp/multicluster-service-export.yaml
        log "✅ Multicluster headless service created"
    else
        log "Skipping multicluster headless service (ENABLE_MULTICLUSTER_HEADLESS=false)"
    fi
    
    # Create Istio VirtualService for Go MySQL API with Ambient Mode
    cat > /tmp/istio-virtualservice.yaml <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: go-mysql-api
  namespace: go-mysql-api
  annotations:
    # Enable Ambient Mode for this VirtualService
    istio.io/dataplane-mode: "ambient"
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/go-mysql-api-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: go-mysql-api-headless.go-mysql-api.svc.cluster.local
        port:
          number: 8088
      weight: 100
    corsPolicy:
      allowOrigins:
      - exact: "*"
      allowMethods:
      - GET
      - POST
      - PUT
      - DELETE
      - OPTIONS
      allowHeaders:
      - "*"
      maxAge: "24h"
EOF
    
    kubectl apply -f /tmp/istio-virtualservice.yaml
    
    # Create Istio DestinationRule for Ambient Mode
    cat > /tmp/istio-destinationrule.yaml <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: go-mysql-api
  namespace: go-mysql-api
  annotations:
    # Enable Ambient Mode for this DestinationRule
    istio.io/dataplane-mode: "ambient"
spec:
  host: go-mysql-api-headless.go-mysql-api.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
        connectTimeout: 30ms
      http:
        http1MaxPendingRequests: 1024
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 10
EOF
    
    kubectl apply -f /tmp/istio-destinationrule.yaml
    
    # Create Istio AuthorizationPolicy
    cat > /tmp/istio-authpolicy.yaml <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: go-mysql-api-auth
  namespace: go-mysql-api
spec:
  selector:
    matchLabels:
      app: go-mysql-api
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/go-mysql-api/sa/default"]
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
        paths: ["/health", "/api/*"]
EOF
    
    kubectl apply -f /tmp/istio-authpolicy.yaml
    
    # Create Istio PeerAuthentication
    cat > /tmp/istio-peer-auth.yaml <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: go-mysql-api-peer-auth
  namespace: go-mysql-api
spec:
  mtls:
    mode: PERMISSIVE
EOF
    
    kubectl apply -f /tmp/istio-peer-auth.yaml
    
    # Create Waypoint proxy for Ambient Mode
    cat > /tmp/istio-waypoint.yaml <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: go-mysql-api-waypoint
  namespace: go-mysql-api
  annotations:
    istio.io/waypoint-for: "go-mysql-api"
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
  - name: metrics
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
  - name: health
    port: 8080
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
    
    kubectl apply -f /tmp/istio-waypoint.yaml
    
    # Create L4 AuthorizationPolicy for Ambient Mode
    cat > /tmp/istio-l4-authorizationpolicy.yaml <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: go-mysql-api-l4-auth
  namespace: go-mysql-api
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: go-mysql-api-waypoint
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/go-mysql-api/sa/go-mysql-api"]
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
        ports: ["8088", "9090", "8080"]
  action: ALLOW
EOF
    
    kubectl apply -f /tmp/istio-l4-authorizationpolicy.yaml
    
    # Verify Istio Ambient Mode installation
    log "Verifying Istio Ambient Mode installation..."
    istioctl verify-install
    kubectl get pods -n istio-system
    kubectl get daemonset -n istio-system
    
    # Check Ambient Mode status
    log "Checking Ambient Mode status..."
    istioctl analyze --namespace go-mysql-api
    kubectl get waypoints -n go-mysql-api
    
    log "✅ Istio installed successfully in Ambient Mode with headless service"
}

# Function to handle certificate rotation with kubeadm
setup_certificate_rotation() {
    log "Setting up certificate rotation with kubeadm..."
    
    # Create a script for certificate rotation
    cat > /home/ec2-user/rotate-certs.sh <<'EOF'
#!/bin/bash
# Certificate Rotation Script for Kubernetes Control Plane
# This script handles certificate rotation using kubeadm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Function to check certificate expiration
check_cert_expiration() {
    log "Checking certificate expiration dates..."
    
    # Check API server certificate
    if [ -f "/etc/kubernetes/pki/apiserver.crt" ]; then
        exp_date=$(openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate | cut -d= -f2)
        log "API Server certificate expires: $exp_date"
    fi
    
    # Check etcd certificates
    if [ -f "/etc/kubernetes/pki/etcd/server.crt" ]; then
        exp_date=$(openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -enddate | cut -d= -f2)
        log "etcd server certificate expires: $exp_date"
    fi
    
    # Check kubelet certificate
    if [ -f "/var/lib/kubelet/pki/kubelet.crt" ]; then
        exp_date=$(openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -noout -enddate | cut -d= -f2)
        log "Kubelet certificate expires: $exp_date"
    fi
}

# Function to rotate certificates
rotate_certificates() {
    log "Starting certificate rotation..."
    
    # Backup current certificates
    log "Backing up current certificates..."
    backup_dir="/etc/kubernetes/pki/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r /etc/kubernetes/pki/* "$backup_dir/"
    
    # Rotate certificates using kubeadm
    log "Rotating certificates with kubeadm..."
    kubeadm certs renew all
    
    # Verify new certificates
    log "Verifying new certificates..."
    kubeadm certs check-expiration
    
    # Restart control plane components
    log "Restarting control plane components..."
    systemctl restart kubelet
    
    # Wait for API server to be ready
    log "Waiting for API server to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=300s
    
    success "Certificate rotation completed successfully"
}

# Function to check certificate health
check_cert_health() {
    log "Checking certificate health..."
    
    # Check if certificates are valid
    if kubeadm certs check-expiration | grep -q "WARNING"; then
        warn "Some certificates are expiring soon or have issues"
        kubeadm certs check-expiration
    else
        success "All certificates are healthy"
    fi
}

# Main execution
case "${1:-check}" in
    "check")
        check_cert_expiration
        check_cert_health
        ;;
    "rotate")
        rotate_certificates
        ;;
    "backup")
        backup_dir="/etc/kubernetes/pki/backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r /etc/kubernetes/pki/* "$backup_dir/"
        success "Certificates backed up to $backup_dir"
        ;;
    *)
        echo "Usage: $0 {check|rotate|backup}"
        echo "  check  - Check certificate expiration and health"
        echo "  rotate - Rotate all certificates"
        echo "  backup - Backup current certificates"
        exit 1
        ;;
esac
EOF
    
    # Make the script executable
    chmod +x /home/ec2-user/rotate-certs.sh
    chown ec2-user:ec2-user /home/ec2-user/rotate-certs.sh
    
    # Create a systemd timer for automatic certificate rotation
    cat > /etc/systemd/system/k8s-cert-rotation.timer <<EOF
[Unit]
Description=Kubernetes Certificate Rotation Timer
Requires=k8s-cert-rotation.service

[Timer]
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF
    
    cat > /etc/systemd/system/k8s-cert-rotation.service <<EOF
[Unit]
Description=Kubernetes Certificate Rotation Service
After=network.target

[Service]
Type=oneshot
ExecStart=/home/ec2-user/rotate-certs.sh rotate
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start the timer
    systemctl daemon-reload
    systemctl enable k8s-cert-rotation.timer
    systemctl start k8s-cert-rotation.timer
    
    # Check certificate status
    log "Checking initial certificate status..."
    /home/ec2-user/rotate-certs.sh check
    
    log "✅ Certificate rotation setup completed"
    log "   Manual rotation: sudo /home/ec2-user/rotate-certs.sh rotate"
    log "   Check status: /home/ec2-user/rotate-certs.sh check"
    log "   Automatic rotation: Monthly via systemd timer"
}

# Function to generate cluster certificates and create first user
setup_cluster_access() {
    log "Setting up cluster certificates and first user access..."
    
    # Create directory for cluster certificates
    mkdir -p /home/ec2-user/.kube/cluster-certs
    cd /home/ec2-user/.kube/cluster-certs
    
    # Generate CA certificate for cluster
    log "Generating cluster CA certificate..."
    cat > /tmp/cluster-ca.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = ${CLUSTER_NAME}
OU = DevOps
CN = ${CLUSTER_NAME}-ca

[v3_req]
basicConstraints = CA:TRUE
keyUsage = keyEncipherment, dataEncipherment, keyCertSign, cRLSign
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CLUSTER_NAME}
DNS.2 = *.${CLUSTER_NAME}.cluster.local
DNS.3 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
EOF
    
    # Generate CA private key and certificate
    openssl genrsa -out cluster-ca.key 4096
    openssl req -new -x509 -key cluster-ca.key -sha256 -subj "/C=US/ST=CA/L=San Francisco/O=${CLUSTER_NAME}/OU=DevOps/CN=${CLUSTER_NAME}-ca" -days 3650 -out cluster-ca.crt -extensions v3_req -extfile /tmp/cluster-ca.conf
    
    # Generate server certificate for API server
    log "Generating API server certificate..."
    cat > /tmp/api-server.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = ${CLUSTER_NAME}
OU = DevOps
CN = kube-apiserver

[v3_req]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = ${CLUSTER_NAME}
DNS.6 = *.${CLUSTER_NAME}.cluster.local
DNS.7 = *.kube-system.svc.cluster.local
DNS.8 = *.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
IP.3 = $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
IP.4 = 10.96.0.1
EOF
    
    # Generate API server private key and certificate signing request
    openssl genrsa -out api-server.key 2048
    openssl req -new -key api-server.key -out api-server.csr -subj "/C=US/ST=CA/L=San Francisco/O=${CLUSTER_NAME}/OU=DevOps/CN=kube-apiserver" -extensions v3_req -extfile /tmp/api-server.conf
    
    # Sign the API server certificate with CA
    openssl x509 -req -in api-server.csr -CA cluster-ca.crt -CAkey cluster-ca.key -CAcreateserial -out api-server.crt -days 365 -extensions v3_req -extfile /tmp/api-server.conf
    
    # Generate client certificate for ArgoCD
    log "Generating ArgoCD client certificate..."
    cat > /tmp/argocd-client.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = ${CLUSTER_NAME}
OU = DevOps
CN = argocd-admin

[v3_req]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = clientAuth
EOF
    
    # Generate ArgoCD private key and certificate signing request
    openssl genrsa -out argocd-admin.key 2048
    openssl req -new -key argocd-admin.key -out argocd-admin.csr -subj "/C=US/ST=CA/L=San Francisco/O=${CLUSTER_NAME}/OU=DevOps/CN=argocd-admin" -extensions v3_req -extfile /tmp/argocd-client.conf
    
    # Sign the ArgoCD certificate with CA
    openssl x509 -req -in argocd-admin.csr -CA cluster-ca.crt -CAkey cluster-ca.key -CAcreateserial -out argocd-admin.crt -days 365 -extensions v3_req -extfile /tmp/argocd-client.conf
    
    # Generate client certificate for GitHub Actions runner
    log "Generating GitHub Actions runner certificate..."
    cat > /tmp/github-runner.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = ${CLUSTER_NAME}
OU = DevOps
CN = github-runner

[v3_req]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = clientAuth
EOF
    
    # Generate GitHub runner private key and certificate signing request
    openssl genrsa -out github-runner.key 2048
    openssl req -new -key github-runner.key -out github-runner.csr -subj "/C=US/ST=CA/L=San Francisco/O=${CLUSTER_NAME}/OU=DevOps/CN=github-runner" -extensions v3_req -extfile /tmp/github-runner.conf
    
    # Sign the GitHub runner certificate with CA
    openssl x509 -req -in github-runner.csr -CA cluster-ca.crt -CAkey cluster-ca.key -CAcreateserial -out github-runner.crt -days 365 -extensions v3_req -extfile /tmp/github-runner.conf
    
    # Create kubeconfig for ArgoCD
    log "Creating kubeconfig for ArgoCD..."
    cat > /home/ec2-user/argocd-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443
    certificate-authority-data: $(cat cluster-ca.crt | base64 -w 0)
contexts:
- name: argocd-admin@${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    user: argocd-admin
current-context: argocd-admin@${CLUSTER_NAME}
users:
- name: argocd-admin
  user:
    client-certificate-data: $(cat argocd-admin.crt | base64 -w 0)
    client-key-data: $(cat argocd-admin.key | base64 -w 0)
EOF
    
    # Create kubeconfig for GitHub Actions runner
    log "Creating kubeconfig for GitHub Actions runner..."
    cat > /home/ec2-user/github-runner-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443
    certificate-authority-data: $(cat cluster-ca.crt | base64 -w 0)
contexts:
- name: github-runner@${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    user: github-runner
current-context: github-runner@${CLUSTER_NAME}
users:
- name: github-runner
  user:
    client-certificate-data: $(cat github-runner.crt | base64 -w 0)
    client-key-data: $(cat github-runner.key | base64 -w 0)
EOF
    
    # Create RBAC for ArgoCD admin
    log "Creating RBAC for ArgoCD admin..."
    cat > /tmp/argocd-admin-rbac.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-admin
subjects:
- kind: ServiceAccount
  name: argocd-admin
  namespace: kube-system
- kind: User
  name: argocd-admin
  apiGroup: rbac.authorization.k8s.io
EOF
    
    kubectl apply -f /tmp/argocd-admin-rbac.yaml
    
    # Create RBAC for GitHub Actions runner
    log "Creating RBAC for GitHub Actions runner..."
    cat > /tmp/github-runner-rbac.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-runner
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: github-runner
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets", "namespaces"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses", "networkpolicies"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-runner
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: github-runner
subjects:
- kind: ServiceAccount
  name: github-runner
  namespace: kube-system
- kind: User
  name: github-runner
  apiGroup: rbac.authorization.k8s.io
EOF
    
    kubectl apply -f /tmp/github-runner-rbac.yaml
    
    # Create a script to install ArgoCD
    cat > /home/ec2-user/install-argocd.sh <<'EOF'
#!/bin/bash
# ArgoCD Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Create ArgoCD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
log "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Create ArgoCD admin user secret
kubectl create secret generic argocd-admin-credentials \
    --from-literal=username=admin \
    --from-literal=password="$ARGOCD_PASSWORD" \
    -n argocd \
    --dry-run=client -o yaml | kubectl apply -f -

# Patch ArgoCD server to use HTTPS
kubectl patch deployment argocd-server -n argocd -p '{"spec":{"template":{"spec":{"containers":[{"name":"argocd-server","args":["--insecure"]}]}}}}'

# Create ArgoCD application for Go MySQL API
cat > /tmp/argocd-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: go-mysql-api
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/blind3dd/database_CI.git
    targetRevision: HEAD
    path: go-mysql-api/chart
  destination:
    server: https://kubernetes.default.svc
    namespace: go-mysql-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
EOF

kubectl apply -f /tmp/argocd-app.yaml

success "ArgoCD installed successfully"
log "ArgoCD admin password: $ARGOCD_PASSWORD"
log "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
EOF
    
    chmod +x /home/ec2-user/install-argocd.sh
    chown ec2-user:ec2-user /home/ec2-user/install-argocd.sh
    
    # Set proper permissions for certificates
    chmod 600 /home/ec2-user/.kube/cluster-certs/*.key
    chmod 644 /home/ec2-user/.kube/cluster-certs/*.crt
    chown -R ec2-user:ec2-user /home/ec2-user/.kube/cluster-certs
    
    # Create a summary file
    cat > /home/ec2-user/cluster-access-summary.txt <<EOF
# Kubernetes Cluster Access Summary
# Generated: $(date)

## Cluster Information
- Cluster Name: ${CLUSTER_NAME}
- API Server: https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443
- CA Certificate: /home/ec2-user/.kube/cluster-certs/cluster-ca.crt

## Available Kubeconfigs
1. ArgoCD Admin: /home/ec2-user/argocd-kubeconfig.yaml
2. GitHub Runner: /home/ec2-user/github-runner-kubeconfig.yaml

## Usage Examples
# Test ArgoCD access
kubectl --kubeconfig=/home/ec2-user/argocd-kubeconfig.yaml get nodes

# Test GitHub Runner access
kubectl --kubeconfig=/home/ec2-user/github-runner-kubeconfig.yaml get pods --all-namespaces

# Install ArgoCD
./install-argocd.sh

## Certificate Expiration
- CA Certificate: $(openssl x509 -in /home/ec2-user/.kube/cluster-certs/cluster-ca.crt -noout -enddate | cut -d= -f2)
- API Server Certificate: $(openssl x509 -in /home/ec2-user/.kube/cluster-certs/api-server.crt -noout -enddate | cut -d= -f2)
- ArgoCD Client Certificate: $(openssl x509 -in /home/ec2-user/.kube/cluster-certs/argocd-admin.crt -noout -enddate | cut -d= -f2)
- GitHub Runner Certificate: $(openssl x509 -in /home/ec2-user/.kube/cluster-certs/github-runner.crt -noout -enddate | cut -d= -f2)

## Security Notes
- Keep private keys secure and do not share them
- Rotate certificates before expiration
- Use the provided kubeconfigs for secure access
EOF
    
    chown ec2-user:ec2-user /home/ec2-user/cluster-access-summary.txt
    
    log "✅ Cluster certificates and access setup completed"
    log "   ArgoCD kubeconfig: /home/ec2-user/argocd-kubeconfig.yaml"
    log "   GitHub Runner kubeconfig: /home/ec2-user/github-runner-kubeconfig.yaml"
    log "   Install ArgoCD: /home/ec2-user/install-argocd.sh"
    log "   Summary: /home/ec2-user/cluster-access-summary.txt"
}

# Function to create Go MySQL API namespace and resources
create_go_mysql_api_resources() {
    log "Creating Go MySQL API namespace and resources..."
    
    # Create namespace
    kubectl create namespace go-mysql-api --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ConfigMap for database connection
    cat > /tmp/db-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: go-mysql-api-config
  namespace: go-mysql-api
data:
  DB_HOST: "$RDS_ENDPOINT"
  DB_PORT: "$RDS_PORT"
  DB_NAME: "$RDS_DATABASE"
  DB_USER: "$RDS_USERNAME"
  APP_PORT: "8088"
  APP_ENV: "production"
  LOG_LEVEL: "info"
  AWS_REGION: "$AWS_REGION"
EOF
    
    kubectl apply -f /tmp/db-config.yaml
    
    # Create Secret for database password
    local password=$(get_db_password)
    kubectl create secret generic go-mysql-api-secrets \
        --namespace go-mysql-api \
        --from-literal=DB_PASSWORD="$password" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log "✅ Go MySQL API resources created successfully"
}

# Function to deploy Go MySQL API application
deploy_go_mysql_api() {
    log "Deploying Go MySQL API application..."
    
    # Create deployment with feature flags
    cat > /tmp/go-mysql-api-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-mysql-api
  namespace: go-mysql-api
  labels:
    app: go-mysql-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: go-mysql-api
  template:
    metadata:
      labels:
        app: go-mysql-api
      annotations:
        # Feature flag annotations
        feature-flags/multicluster-headless: "${ENABLE_MULTICLUSTER_HEADLESS}"
        feature-flags/native-sidecars: "${ENABLE_NATIVE_SIDECARS}"
    spec:
      containers:
      - name: go-mysql-api
        image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/go-mysql-api:latest
        ports:
        - containerPort: 8088
          name: http
        - containerPort: 9090
          name: metrics
        - containerPort: 8080
          name: health
EOF
    
    # Add additional ports for multicluster if enabled
    if [ "$ENABLE_MULTICLUSTER_HEADLESS" = "true" ]; then
        cat >> /tmp/go-mysql-api-deployment.yaml <<EOF
        - containerPort: 9091
          name: grpc
        - containerPort: 9092
          name: admin
EOF
    fi
    
    # Continue with the rest of the deployment
    cat >> /tmp/go-mysql-api-deployment.yaml <<EOF
        envFrom:
        - configMapRef:
            name: go-mysql-api-config
        - secretRef:
            name: go-mysql-api-secrets
        env:
        - name: ENABLE_MULTICLUSTER_HEADLESS
          value: "${ENABLE_MULTICLUSTER_HEADLESS}"
        - name: ENABLE_NATIVE_SIDECARS
          value: "${ENABLE_NATIVE_SIDECARS}"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8088
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8088
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
    
    kubectl apply -f /tmp/go-mysql-api-deployment.yaml
    
    # Create service
    cat > /tmp/go-mysql-api-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: go-mysql-api
  namespace: go-mysql-api
spec:
  selector:
    app: go-mysql-api
  ports:
  - port: 8088
    targetPort: 8088
    protocol: TCP
  type: ClusterIP
EOF
    
    kubectl apply -f /tmp/go-mysql-api-service.yaml
    
    # Create ingress (if using ingress controller)
    cat > /tmp/go-mysql-api-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-mysql-api-ingress
  namespace: go-mysql-api
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.${ENVIRONMENT}-${SERVICE_NAME}.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: go-mysql-api
            port:
              number: 8088
EOF
    
    kubectl apply -f /tmp/go-mysql-api-ingress.yaml
    
    log "✅ Go MySQL API application deployed successfully"
}

# Function to display feature flags status
display_feature_flags() {
    log "🔧 Feature Flags Configuration:"
    log "   ENABLE_MULTICLUSTER_HEADLESS: ${ENABLE_MULTICLUSTER_HEADLESS}"
    log "   ENABLE_NATIVE_SIDECARS: ${ENABLE_NATIVE_SIDECARS}"
    
    if [ "$ENABLE_MULTICLUSTER_HEADLESS" = "true" ]; then
        log "   ✅ Multicluster headless services will be enabled"
    else
        log "   ❌ Multicluster headless services disabled"
    fi
    
    if [ "$ENABLE_NATIVE_SIDECARS" = "true" ]; then
        log "   ✅ Native sidecars will be enabled"
    else
        log "   ❌ Native sidecars disabled"
    fi
    
    log ""
}

# Function to verify cluster health
verify_cluster_health() {
    log "Verifying cluster health..."
    
    # Check nodes
    log "Checking nodes..."
    kubectl get nodes
    
    # Check pods
    log "Checking pods..."
    kubectl get pods --all-namespaces
    
    # Check services
    log "Checking services..."
    kubectl get services --all-namespaces
    
    # Test database connectivity from within cluster
    log "Testing database connectivity from within cluster..."
    kubectl run db-test --image=mysql:8.0 --rm -it --restart=Never -- \
        mysql -h "$RDS_ENDPOINT" -P "$RDS_PORT" -u "$RDS_USERNAME" -p"$(get_db_password)" -e "SELECT 1;" 2>/dev/null || warn "Database test failed"
    
    log "✅ Cluster health verification completed"
}

# Main execution
main() {
    log "🚀 Starting Kubernetes Control Plane Setup"
    log "Environment: $ENVIRONMENT"
    log "Service: $SERVICE_NAME"
    log "Cluster: $CLUSTER_NAME"
    log "Pod CIDR: $POD_CIDR"
    log "Service CIDR: $SERVICE_CIDR"
    
    # Test database connectivity
    test_database_connection
    
    # Check if this is the first control plane node
    if is_first_control_plane; then
        init_first_control_plane
        install_cert_manager
        configure_coredns
        install_istio
        create_go_mysql_api_resources
        deploy_go_mysql_api
    else
        join_control_plane
    fi
    
    # Verify cluster health
    verify_cluster_health
    
    log "🎉 Kubernetes Control Plane Setup completed successfully!"
    log "📋 Next steps:"
    log "   1. Join additional control plane nodes using the join command"
    log "   2. Add worker nodes to the cluster"
    log "   3. Configure ingress controller if needed"
    log "   4. Set up monitoring and logging"
    log "   5. Configure backup and disaster recovery"
    
    # Fun completion message
    if command -v cowsay &> /dev/null && command -v fortune &> /dev/null; then
        echo ""
        fortune | cowsay
    fi
}

# Run main function
main "$@"
