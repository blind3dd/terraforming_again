#!/bin/bash
# Assume AWS Role and Export Credentials to Current Session
# Usage: source hack/assume-role-session.sh dev
#    or: source hack/assume-role-session.sh test

set -e

ENVIRONMENT="${1:-dev}"

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "test" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo "❌ Invalid environment. Use: dev, test, or prod"
    return 1 2>/dev/null || exit 1
fi

echo "🔐 Assuming role for environment: $ENVIRONMENT"
echo ""

# Configuration per environment
case "$ENVIRONMENT" in
    dev)
        ROLE_ARN="arn:aws:iam::690248313240:role/iacrole"
        MFA_SERIAL="arn:aws:iam::690248313240:mfa/mfa_sts"
        BASE_PROFILE="default"
        ;;
    test)
        ROLE_ARN="arn:aws:iam::690248313240:role/iacrole-test"
        MFA_SERIAL="arn:aws:iam::690248313240:mfa/mfa_sts_test"
        BASE_PROFILE="test"
        ;;
    prod)
        ROLE_ARN="arn:aws:iam::987654321098:role/iacrole-prod"
        MFA_SERIAL="arn:aws:iam::690248313240:u2f/user/iacrunner/test-SIXWC3CWFJHNTEB3EBMNPQ6J2Q"
        BASE_PROFILE="prod"
        ;;
esac

echo "📋 Configuration:"
echo "  Role: $ROLE_ARN"
echo "  MFA:  $MFA_SERIAL"
echo "  Base: $BASE_PROFILE"
echo ""

# Prompt for MFA code
read -p "Enter MFA code: " MFA_CODE

echo ""
echo "🔄 Assuming role..."

# Clear any existing session tokens
unset AWS_SESSION_TOKEN

# Set base credentials from profile
if [ "$BASE_PROFILE" == "default" ]; then
    # Read default credentials
    BASE_KEY=$(awk -F' = ' '/^\[default\]/,/^\[/ {if ($1 == "aws_access_key_id") print $2}' ~/.aws/credentials | head -1 | tr -d ' ')
    BASE_SECRET=$(awk -F' = ' '/^\[default\]/,/^\[/ {if ($1 == "aws_secret_access_key") print $2}' ~/.aws/credentials | head -1 | tr -d ' ')
else
    # Read profile-specific credentials
    BASE_KEY=$(awk -F' = ' "/^\[$BASE_PROFILE\]/,/^\[/ {if (\$1 == \"aws_access_key_id\") print \$2}" ~/.aws/credentials | head -1 | tr -d ' ')
    BASE_SECRET=$(awk -F' = ' "/^\[$BASE_PROFILE\]/,/^\[/ {if (\$1 == \"aws_secret_access_key\") print \$2}" ~/.aws/credentials | head -1 | tr -d ' ')
fi

if [ -z "$BASE_KEY" ] || [ -z "$BASE_SECRET" ]; then
    echo "❌ Could not find credentials for profile: $BASE_PROFILE"
    echo "   Check ~/.aws/credentials file"
    return 1 2>/dev/null || exit 1
fi

export AWS_ACCESS_KEY_ID="$BASE_KEY"
export AWS_SECRET_ACCESS_KEY="$BASE_SECRET"

echo "✅ Using base credentials from [$BASE_PROFILE] profile"

# Assume role
CREDS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "cli-${ENVIRONMENT}-$(date +%s)" \
    --serial-number "$MFA_SERIAL" \
    --token-code "$MFA_CODE" \
    --duration-seconds 3600 \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo "Failed to assume role:"
    echo "$CREDS"
    return 1 2>/dev/null || exit 1
fi

# Export credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')
export AWS_REGION="us-east-1"
export AWS_DEFAULT_REGION="us-east-1"

# Get expiration
EXPIRATION=$(echo "$CREDS" | jq -r '.Credentials.Expiration')

echo "✅ Successfully assumed role!"
echo ""
echo "📊 Session details:"
aws sts get-caller-identity
echo ""
echo "⏰ Session expires: $EXPIRATION"
echo ""
echo "💡 Credentials exported to current shell:"
echo "   AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "   AWS_SECRET_ACCESS_KEY=***"
echo "   AWS_SESSION_TOKEN=***"
echo ""
echo "🚀 You can now use AWS CLI and Terraform:"
echo "   aws s3 ls"
echo "   terraform plan"
echo ""
echo "⚠️  To clear this session, run:"
echo "   unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"

