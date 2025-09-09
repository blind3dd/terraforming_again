#!/bin/bash
# Simple CloudInit Script for Go MySQL API
set -e

# Configuration variables
ENVIRONMENT="${environment}"
SERVICE_NAME="${service_name}"
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD_PARAM="${db_password_param}"
ECR_REPOSITORY_URL="${ecr_repository_url}"

echo "Starting Go MySQL API setup..."
echo "Environment: $ENVIRONMENT"
echo "Service: $SERVICE_NAME"
echo "Database Host: $DB_HOST"

# Install Go
curl -O https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ec2-user/.bashrc

# Create simple Go app
mkdir -p /home/ec2-user/go/src/go-mysql-api
cd /home/ec2-user/go/src/go-mysql-api

cat > main.go << 'EOF'
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from Go MySQL API!")
    })
    
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Healthy!")
    })
    
    log.Fatal(http.ListenAndServe(":8088", nil))
}
EOF

# Build and run
/usr/local/go/bin/go build -o go-mysql-api main.go
nohup ./go-mysql-api > app.log 2>&1 &

echo "Go MySQL API setup completed!"
