#!/bin/bash

# Setup Terraform Backend Infrastructure
# This script creates the S3 bucket and DynamoDB table for remote state management

set -e

echo "🚀 Setting up Terraform Backend Infrastructure..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured or no valid credentials"
    echo "Please run: aws configure"
    exit 1
fi

# Get current AWS account and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo "📋 AWS Account: $ACCOUNT_ID"
echo "📋 AWS Region: $REGION"

# Create unique bucket name with account ID
BUCKET_NAME="terraform-state-bucket-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock-${ACCOUNT_ID}"

echo "📦 S3 Bucket Name: $BUCKET_NAME"
echo "🔒 DynamoDB Table Name: $TABLE_NAME"

# Initialize and apply backend setup
echo "🔧 Initializing Terraform for backend setup..."
terraform init

echo "📋 Planning backend infrastructure..."
terraform plan -var="create_backend=true" -var="state_bucket_name=$BUCKET_NAME" -var="state_table_name=$TABLE_NAME" -var="region=$REGION" -target=module.terraform_backend

echo "🚀 Creating backend infrastructure..."
terraform apply -auto-approve -var="create_backend=true" -var="state_bucket_name=$BUCKET_NAME" -var="state_table_name=$TABLE_NAME" -var="region=$REGION" -target=module.terraform_backend

# Get outputs
BUCKET_NAME_OUTPUT=$(terraform output -raw s3_bucket_name)
TABLE_NAME_OUTPUT=$(terraform output -raw dynamodb_table_name)

echo ""
echo "✅ Backend infrastructure created successfully!"
echo "📦 S3 Bucket: $BUCKET_NAME_OUTPUT"
echo "🔒 DynamoDB Table: $TABLE_NAME_OUTPUT"
echo ""

# Update provider.tf with actual values
echo "🔧 Updating provider.tf with actual backend values..."
sed -i.bak "s/terraform-state-bucket/$BUCKET_NAME_OUTPUT/g" provider.tf
sed -i.bak "s/terraform-state-lock/$TABLE_NAME_OUTPUT/g" provider.tf
sed -i.bak "s/us-east-1/$REGION/g" provider.tf

echo "✅ provider.tf updated with:"
echo "   - Bucket: $BUCKET_NAME_OUTPUT"
echo "   - Table: $TABLE_NAME_OUTPUT"
echo "   - Region: $REGION"
echo ""

echo "🎯 Next steps:"
echo "1. Run: terraform init"
echo "2. Run: terraform init -migrate-state"
echo "3. Verify: terraform plan"
echo ""
echo "⚠️  Note: The backend-setup.tf file can be removed after setup is complete"
