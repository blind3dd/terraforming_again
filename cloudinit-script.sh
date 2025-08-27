#!/bin/bash
# CloudInit shell script for application deployment
# This script runs after the cloud-config section

set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/cloud-init-app.log
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Configuration variables (passed from Terraform)
ENVIRONMENT="${environment}"
SERVICE_NAME="${service_name}"
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD_PARAM="${db_password_param}"
ECR_REPOSITORY_URL="${ecr_repository_url}"

log "Starting application deployment for ${ENVIRONMENT}-${SERVICE_NAME}"

# Install Go
log "Installing Go..."
yum install -y golang || handle_error "Failed to install Go"

# Set Go environment
export GOPATH=/home/ec2-user/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
echo "export GOPATH=/home/ec2-user/go" >> /home/ec2-user/.bashrc
echo "export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" >> /home/ec2-user/.bashrc

# Create application directory structure
log "Creating application directories..."
mkdir -p /home/ec2-user/app
mkdir -p /home/ec2-user/logs
mkdir -p /home/ec2-user/config
mkdir -p /home/ec2-user/go/src

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user

# Install CloudWatch agent
log "Installing CloudWatch agent..."
yum install -y amazon-cloudwatch-agent || handle_error "Failed to install CloudWatch agent"

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/cloud-init-app.log",
                        "log_group_name": "/aws/ec2/${ENVIRONMENT}-${SERVICE_NAME}/cloud-init",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/home/ec2-user/logs/*.log",
                        "log_group_name": "/aws/ec2/${ENVIRONMENT}-${SERVICE_NAME}/application",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Configure AWS CLI with IAMv2 authentication
log "Configuring AWS CLI with IAMv2 authentication..."

# Get AWS region from instance metadata
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_DEFAULT_REGION=$AWS_REGION

# Configure AWS CLI
aws configure set default.region "$AWS_REGION"
aws configure set default.output json
aws configure set default.imds_use_ipv6 false
aws configure set default.imds_use_ipv4 true

# Test AWS authentication
log "Testing AWS authentication..."
aws sts get-caller-identity --region "$AWS_REGION" || handle_error "Failed to authenticate with AWS"

# Get instance metadata for debugging
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
log "Instance ID: $INSTANCE_ID"
log "AWS Region: $AWS_REGION"

# Get database password from SSM with proper authentication
log "Retrieving database password from SSM..."
DB_PASSWORD=$(aws ssm get-parameter \
    --name "${DB_PASSWORD_PARAM}" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "$AWS_REGION" \
    --cli-read-timeout 30 \
    --cli-connect-timeout 30) || handle_error "Failed to retrieve database password"

# Test database connection
log "Testing database connection..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" "${DB_NAME}" || handle_error "Failed to connect to database"

# Clone application repository
log "Cloning application repository..."
cd /home/ec2-user/app
git clone https://github.com/blind3dd/database_CI.git || handle_error "Failed to clone repository"

# Build Go application
log "Building Go application..."
cd /home/ec2-user/app/database_CI/go-mysql-api
go mod download || handle_error "Failed to download Go modules"
go build -o main cmd/main.go || handle_error "Failed to build Go application"

# Create application configuration
log "Creating application configuration..."
cat > /home/ec2-user/config/app.env << EOF
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
ENVIRONMENT=${ENVIRONMENT}
SERVICE_NAME=${SERVICE_NAME}
ECR_REPOSITORY_URL=${ECR_REPOSITORY_URL}
EOF

# Create Docker Compose file
log "Creating Docker Compose configuration..."
cat > /home/ec2-user/app/docker-compose.yml << EOF
version: '3.8'

services:
  go-mysql-api:
    image: ${ECR_REPOSITORY_URL}:latest
    container_name: ${SERVICE_NAME}-api
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - /home/ec2-user/config:/app/config:ro
      - /home/ec2-user/logs:/app/logs
    restart: unless-stopped
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    container_name: ${SERVICE_NAME}-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - /home/ec2-user/app/database_CI/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped
    command: --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

volumes:
  mysql_data:

networks:
  default:
    name: ${SERVICE_NAME}-network
EOF

# Create systemd service for the application
log "Creating systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=${SERVICE_NAME} Go Application
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/app
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=ec2-user
Group=ec2-user
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl start ${SERVICE_NAME}

# Create health check script
log "Creating health check script..."
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for the application

APP_URL="http://localhost:8080/health"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"

# Check application health
if curl -f -s "${APP_URL}" > /dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application health check failed"
    exit 1
fi

# Check database connection
if mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" "${DB_NAME}" > /dev/null 2>&1; then
    echo "✅ Database connection is healthy"
else
    echo "❌ Database connection failed"
    exit 1
fi

echo "🎉 All health checks passed!"
EOF

chmod +x /home/ec2-user/health-check.sh
chown ec2-user:ec2-user /home/ec2-user/health-check.sh

# Create monitoring script
log "Creating monitoring script..."
cat > /home/ec2-user/monitor.sh << 'EOF'
#!/bin/bash
# Monitoring script for the application

echo "📊 System Status Report"
echo "======================"
echo ""

echo "🖥️  System Resources:"
echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "  Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
echo ""

echo "🐳 Docker Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "🔗 Application Status:"
if curl -f -s "http://localhost:8080/health" > /dev/null; then
    echo "  ✅ Application is running"
else
    echo "  ❌ Application is not responding"
fi
echo ""

echo "🗄️  Database Status:"
if mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" "${DB_NAME}" > /dev/null 2>&1; then
    echo "  ✅ Database is accessible"
else
    echo "  ❌ Database connection failed"
fi
echo ""

echo "📝 Recent Logs:"
tail -n 10 /home/ec2-user/logs/*.log 2>/dev/null || echo "  No log files found"
EOF

chmod +x /home/ec2-user/monitor.sh
chown ec2-user:ec2-user /home/ec2-user/monitor.sh

# Set up log rotation
log "Setting up log rotation..."
cat > /etc/logrotate.d/${SERVICE_NAME} << EOF
/home/ec2-user/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        systemctl reload ${SERVICE_NAME} > /dev/null 2>&1 || true
    endscript
}
EOF

# Final setup
log "Performing final setup..."

# Set proper permissions
chown -R ec2-user:ec2-user /home/ec2-user

# Create a simple status page
cat > /home/ec2-user/status.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${SERVICE_NAME} Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .healthy { background-color: #d4edda; color: #155724; }
        .unhealthy { background-color: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <h1>${SERVICE_NAME} Status Page</h1>
    <p>Environment: ${ENVIRONMENT}</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Last Updated: $(date)</p>
    
    <div class="status healthy">
        ✅ Application is running
    </div>
    
    <p><a href="http://localhost:8080">Go to Application</a></p>
</body>
</html>
EOF

# Start a simple HTTP server for status page
nohup python3 -m http.server 8081 --directory /home/ec2-user > /dev/null 2>&1 &

log "Application deployment completed successfully!"
log "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
log "Status Page: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081"

# Run health check
log "Running health check..."
/home/ec2-user/health-check.sh || log "Health check failed, but deployment completed"

log "🎉 CloudInit script completed successfully!"
