#!/bin/bash

# Enhanced user data script for Go MySQL API EC2 instance
# This script sets up the environment, installs dependencies, and starts the application

set -e  # Exit on any error

    sudo su root
    yum update -y && yum upgrade -y
    yum install golang -y
    yum install mysql-client-core-8.0 -y
    yum install awscli -y

log "Installing required packages"
yum install -y golang mysql-client-core-8.0 awscli amazon-cloudwatch-agent

# Set up Go environment
log "Setting up Go environment"
mkdir -p /home/ec2-user/go/{src,bin,pkg}
chown -R ec2-user:ec2-user /home/ec2-user/go

# Set PATH for Go
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/ec2-user/go/bin
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Create application directory
log "Creating application directory"
[ ! -d /opt/go-mysql-api ] && mkdir -p /opt/go-mysql-api/${var.environment}
chown -R ec2-user:ec2-user /opt/go-mysql-api

# Set proper permissions
log "Setting proper permissions"
find /opt/go-mysql-api -type d -exec chmod 755 {} \;
find /opt/go-mysql-api -type f -exec chmod 644 {} \;

# Configure CloudWatch agent
log "Configuring CloudWatch agent"
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/${var.environment}-${var.service_name}/system",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/opt/go-mysql-api/${var.environment}/application.log",
                        "log_group_name": "/aws/ec2/${var.environment}-${var.service_name}/application",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
log "Starting CloudWatch agent"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Get database password from SSM Parameter Store
log "Retrieving database password from SSM"
DB_PASSWORD=$(aws ssm get-parameter \
    --name ${DB_PASSWORD_PARAM} \
    --region ${var.region} \
    --with-decryption \
    --output text \
    --query Parameter.Value)

if [ -z "$DB_PASSWORD" ]; then
    log "ERROR: Failed to retrieve database password from SSM"
    exit 1
fi

log "Database password retrieved successfully"

# Create application log file
touch /opt/go-mysql-api/${var.environment}/application.log
chown ec2-user:ec2-user /opt/go-mysql-api/${var.environment}/application.log

# Switch to ec2-user for application operations
su - ec2-user << 'EOF'
set -e

# Set environment variables
export DB_USER=${DB_USER}
export DB_PASSWORD=$DB_PASSWORD
export DB_HOST=${DB_HOST}
export DB_PORT=${DB_PORT}
export DB_NAME=${DB_NAME}
export MYSQL_USER=${DB_USER}
export MYSQL_PASSWORD=$DB_PASSWORD
export MYSQL_HOST=${DB_HOST}
export MYSQL_PORT=${DB_PORT}
export MYSQL_DATABASE=${DB_NAME}

# Test database connection
log "Testing database connection"
mysql -h ${DB_HOST} -u ${DB_USER} -p$DB_PASSWORD -e "SELECT 1;" ${DB_NAME} || {
    log "ERROR: Failed to connect to database"
    exit 1
}

log "Database connection successful"

# Build and run the application
log "Building Go application"
cd /app/go-mysql-api
go build -buildvcs=false -o go-api

if [ ! -f go-api ]; then
    log "ERROR: Failed to build Go application"
    exit 1
fi

log "Go application built successfully"

# Run the application with proper logging
log "Starting Go application"
nohup ./go-api > /opt/go-mysql-api/${var.environment}/application.log 2>&1 &

# Wait a moment and check if the application started
sleep 5
if pgrep -f go-api > /dev/null; then
    log "Go application started successfully"
else
    log "ERROR: Failed to start Go application"
    exit 1
fi

EOF

log "User data script completed successfully"