#!/bin/bash

# Load secrets from AWS SSM Parameter Store for Docker Compose
# This script fetches secrets from SSM and exports them as environment variables

set -e

# Configuration
ENVIRONMENT="${ENVIRONMENT:-test}"
SERVICE_NAME="${SERVICE_NAME:-go-mysql-api}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Function to get parameter from SSM
get_ssm_parameter() {
    local param_name="$1"
    local default_value="${2:-}"
    
    echo "Fetching parameter: $param_name" >&2
    
    if aws ssm get-parameter \
        --name "$param_name" \
        --with-decryption \
        --region "$AWS_REGION" \
        --query 'Parameter.Value' \
        --output text 2>/dev/null; then
        return 0
    else
        if [[ -n "$default_value" ]]; then
            echo "Parameter $param_name not found, using default value" >&2
            echo "$default_value"
        else
            echo "ERROR: Parameter $param_name not found and no default value provided" >&2
            return 1
        fi
    fi
}

# Function to export environment variables
export_secrets() {
    echo "Loading secrets from AWS SSM Parameter Store..."
    
    # Database secrets
    export DB_PASSWORD=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/database/password")
    export MYSQL_ROOT_PASSWORD=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/database/root_password" "SecureRootPassword123!")
    export DB_NAME=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/database/name" "mock_user")
    export DB_USER=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/database/user" "db_user")
    
    # API secrets
    export API_KEY=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/api/key")
    export JWT_SECRET=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/api/jwt_secret")
    
    # External service secrets
    export GITHUB_TOKEN=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/external/github_token")
    export SLACK_WEBHOOK_URL=$(get_ssm_parameter "/${ENVIRONMENT}/${SERVICE_NAME}/external/slack_webhook")
    
    echo "Secrets loaded successfully!"
}

# Function to create SSM parameters (for initial setup)
create_ssm_parameters() {
    echo "Creating SSM parameters for initial setup..."
    
    # Generate random passwords
    local db_password=$(openssl rand -base64 32)
    local root_password=$(openssl rand -base64 32)
    local api_key=$(openssl rand -base64 32)
    local jwt_secret=$(openssl rand -base64 32)
    
    # Create database parameters
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/database/password" \
        --value "$db_password" \
        --type "SecureString" \
        --description "Database password for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/database/root_password" \
        --value "$root_password" \
        --type "SecureString" \
        --description "MySQL root password for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/database/name" \
        --value "mock_user" \
        --type "String" \
        --description "Database name for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/database/user" \
        --value "db_user" \
        --type "String" \
        --description "Database user for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    # Create API parameters
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/api/key" \
        --value "$api_key" \
        --type "SecureString" \
        --description "API key for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    aws ssm put-parameter \
        --name "/${ENVIRONMENT}/${SERVICE_NAME}/api/jwt_secret" \
        --value "$jwt_secret" \
        --type "SecureString" \
        --description "JWT secret for ${SERVICE_NAME}" \
        --region "$AWS_REGION"
    
    echo "SSM parameters created successfully!"
    echo "You can now run: source ./load-secrets.sh && docker-compose -f docker-compose-secure.yml up"
}

# Function to run docker-compose with secrets
run_docker_compose() {
    echo "Starting services with secrets from SSM..."
    docker-compose -f docker-compose-secure.yml up -d
}

# Main script logic
case "${1:-export}" in
    "export")
        export_secrets
        ;;
    "create")
        create_ssm_parameters
        ;;
    "run")
        export_secrets
        run_docker_compose
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [export|create|run|help]"
        echo ""
        echo "Commands:"
        echo "  export  - Export secrets from SSM as environment variables (default)"
        echo "  create  - Create initial SSM parameters with random values"
        echo "  run     - Export secrets and run docker-compose"
        echo "  help    - Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  ENVIRONMENT  - Environment name (default: test)"
        echo "  SERVICE_NAME - Service name (default: go-mysql-api)"
        echo "  AWS_REGION   - AWS region (default: us-east-1)"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac



