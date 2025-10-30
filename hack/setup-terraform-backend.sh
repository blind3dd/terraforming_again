#!/usr/bin/env bash
# Create Terraform backend resources (S3 bucket and DynamoDB table)
# Or switch to local backend if you don't have permissions

set -e

REGION="us-east-1"
BUCKET_NAME="terraform-state-bucket"
DYNAMODB_TABLE="terraform-state-lock"

echo "🔧 Terraform Backend Setup"
echo ""
echo "Options:"
echo "1. Create S3 bucket and DynamoDB table (requires AWS permissions)"
echo "2. Switch to local backend (no AWS resources needed)"
echo ""
read -p "Choose option [1/2]: " option

case $option in
  1)
    echo ""
    echo "🏗️  Creating S3 bucket and DynamoDB table..."
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
      echo "✅ S3 bucket already exists: $BUCKET_NAME"
    else
      echo "📦 Creating S3 bucket: $BUCKET_NAME"
      aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" || \
      aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION"
      
      # Enable versioning
      aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
      
      # Enable encryption
      aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
          "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
              "SSEAlgorithm": "AES256"
            }
          }]
        }'
      
      echo "✅ S3 bucket created and configured"
    fi
    
    # Check if DynamoDB table exists
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
      echo "✅ DynamoDB table already exists: $DYNAMODB_TABLE"
    else
      echo "📊 Creating DynamoDB table: $DYNAMODB_TABLE"
      aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
      
      echo "⏳ Waiting for table to be active..."
      aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
      echo "✅ DynamoDB table created"
    fi
    
    echo ""
    echo "✅ Backend resources created!"
    echo "💡 You can now run: terraform init"
    ;;
    
  2)
    echo ""
    echo "📝 Creating local backend configuration..."
    
    # Create backup of current backend config
    BACKUP_DIR="backups/backend-config-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Update backend in environment files
    for env_file in infrastructure/terraform/environments/{dev,test,prod}/main.tf; do
      if [ -f "$env_file" ]; then
        echo "📝 Updating: $env_file"
        cp "$env_file" "$BACKUP_DIR/$(basename $env_file).bak"
        
        # Replace S3 backend with local backend
        sed -i.bak 's/backend "s3"/backend "local"/' "$env_file"
        sed -i.bak '/bucket.*=.*terraform-state-bucket/,/encrypt.*=.*true/d' "$env_file"
        sed -i.bak '/backend "local"/a\
    path = "terraform.tfstate"
' "$env_file"
        rm -f "$env_file.bak"
      fi
    done
    
    echo "✅ Switched to local backend"
    echo "💡 State files will be stored locally in each directory"
    echo "💡 Backups saved to: $BACKUP_DIR"
    ;;
    
  *)
    echo "❌ Invalid option"
    exit 1
    ;;
esac

