#!/bin/bash

# Generate DNS Records Script
# This script generates Route53 records from the endpoints configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/endpoints-config.yaml"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        print_error "yq is not installed. Please install yq to parse YAML files."
        print_info "Install with: brew install yq (on macOS) or apt-get install yq (on Ubuntu)"
        exit 1
    fi
}

# Generate Route53 records for an environment
generate_route53_records() {
    local env=$1
    local env_dir="$SCRIPT_DIR/$env"
    
    if [[ ! -d "$env_dir" ]]; then
        print_error "Environment directory does not exist: $env_dir"
        exit 1
    fi
    
    print_info "Generating Route53 records for $env environment..."
    
    # Create temporary file for Route53 records
    local temp_file=$(mktemp)
    
    echo "route53_records = {" > "$temp_file"
    
    # Read endpoints from YAML and generate records
    local endpoints=$(yq eval '.endpoints | keys | .[]' "$CONFIG_FILE")
    
    for endpoint in $endpoints; do
        local path=$(yq eval ".endpoints.$endpoint.path" "$CONFIG_FILE" | sed 's|^/||')
        local service=$(yq eval ".endpoints.$endpoint.service" "$CONFIG_FILE")
        local port=$(yq eval ".endpoints.$endpoint.port" "$CONFIG_FILE")
        local description=$(yq eval ".endpoints.$endpoint.description" "$CONFIG_FILE")
        
        # Only generate records for the current environment
        if [[ "$endpoint" =~ ^$env- ]]; then
            # Generate A record for the endpoint
            echo "  \"$endpoint\" = {" >> "$temp_file"
            echo "    name = \"$endpoint\"" >> "$temp_file"
            echo "    type = \"A\"" >> "$temp_file"
            echo "    ttl = 300" >> "$temp_file"
            echo "    records = [\"10.0.10.10\"]  # Will be updated with actual load balancer IP" >> "$temp_file"
            echo "    zone_type = \"private\"" >> "$temp_file"
            echo "  }" >> "$temp_file"
        fi
    done
    
    echo "}" >> "$temp_file"
    
    # Update the terraform.tfvars file
    local tfvars_file="$env_dir/terraform.tfvars"
    
    if [[ -f "$tfvars_file" ]]; then
        # Remove existing route53_records section
        sed -i.bak '/^route53_records = {/,/^}/d' "$tfvars_file"
        
        # Add new route53_records section
        echo "" >> "$tfvars_file"
        cat "$temp_file" >> "$tfvars_file"
        
        # Clean up backup file
        rm -f "$tfvars_file.bak"
        
        print_success "Updated $tfvars_file with generated Route53 records"
    else
        print_error "terraform.tfvars file not found: $tfvars_file"
        exit 1
    fi
    
    # Clean up temporary file
    rm -f "$temp_file"
}

# Generate load balancer configuration
generate_load_balancer_config() {
    local env=$1
    local env_dir="$SCRIPT_DIR/$env"
    
    print_info "Generating load balancer configuration for $env environment..."
    
    # Create load balancer configuration file
    local lb_config_file="$env_dir/load-balancer.tf"
    
    cat > "$lb_config_file" << 'EOF'
# Load Balancer Configuration
# This file is auto-generated from endpoints-config.yaml

# Application Load Balancer
resource "aws_lb" "internal" {
  name               = "${var.environment}-${var.service_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-internal-alb"
    Environment = var.environment
    Service     = var.service_name
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.service_name}-alb-sg"
    Environment = var.environment
    Service     = var.service_name
  })
}

# Target Group for API
resource "aws_lb_target_group" "api" {
  name     = "${var.environment}-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-api-tg"
    Environment = var.environment
    Service     = var.service_name
  })
}

# ALB Listener
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ALB Listener Rule for API
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
EOF

    print_success "Generated load balancer configuration: $lb_config_file"
}

# Main function
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <environment> [--with-lb]"
        echo ""
        echo "Environments:"
        echo "  dev, test, sandbox"
        echo ""
        echo "Options:"
        echo "  --with-lb    Also generate load balancer configuration"
        echo ""
        echo "Examples:"
        echo "  $0 dev"
        echo "  $0 test --with-lb"
        exit 1
    fi
    
    local env=$1
    local with_lb=false
    
    if [[ "$2" == "--with-lb" ]]; then
        with_lb=true
    fi
    
    check_yq
    generate_route53_records "$env"
    
    if [[ "$with_lb" == "true" ]]; then
        generate_load_balancer_config "$env"
    fi
    
    print_success "DNS records generation completed for $env environment"
}

# Run main function with all arguments
main "$@"
