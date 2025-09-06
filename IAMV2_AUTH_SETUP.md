# IAMv2 Authentication Setup for EC2 Instances

This document describes the IAMv2 (Instance Metadata Service v2) authentication setup for EC2 instances in the Go MySQL API infrastructure.

## What is IAMv2?

IAMv2 (Instance Metadata Service v2) is AWS's enhanced metadata service that provides a more secure way for EC2 instances to access their metadata and temporary credentials. It uses session-oriented requests with tokens that have a configurable lifetime.

## Key Features

- **Token-based authentication**: Requires a token for metadata access
- **Configurable token TTL**: Tokens can be set to expire (default: 6 hours)
- **Enhanced security**: Prevents SSRF attacks
- **Backward compatibility**: Falls back to IMDSv1 if needed

## Implementation Details

### 1. CloudInit Configuration

The CloudInit configuration automatically sets up IAMv2 authentication:

```yaml
# Configure AWS CLI with IAMv2 authentication
- |
  # Get AWS region from instance metadata
  AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  aws configure set default.region "$AWS_REGION"
  aws configure set default.output json
  
  # Configure AWS CLI to use instance metadata service v2
  aws configure set default.imds_use_ipv6 false
  aws configure set default.imds_use_ipv4 true
  
  # Set up AWS CLI to use instance profile
  export AWS_DEFAULT_REGION="$AWS_REGION"
  export AWS_PAGER=""
```

### 2. IAM Role Permissions

The EC2 instance role includes the necessary permissions for IAMv2 authentication:

```json
{
  "Effect": "Allow",
  "Action": [
    "sts:GetCallerIdentity",
    "sts:GetSessionToken",
    "sts:AssumeRole"
  ],
  "Resource": "*"
}
```

### 3. CloudInit Script Authentication

The CloudInit script includes proper IAMv2 authentication handling:

```bash
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
```

## Testing IAMv2 Authentication

### 1. Run the Test Script

Use the provided test script to verify IAMv2 authentication:

```bash
./test-iamv2-auth.sh
```

This script tests:
- AWS CLI installation
- Instance metadata service access
- AWS authentication
- SSM parameter access
- ECR access
- CloudWatch access
- IAM permissions

### 2. Manual Testing

You can also test IAMv2 authentication manually:

```bash
# Test IMDSv2 token retrieval
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Use token to access metadata
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Test AWS authentication
aws sts get-caller-identity

# Test SSM parameter access
aws ssm get-parameter --name "/sandbox/go-mysql-api/db/password" --with-decryption
```

## Troubleshooting

### Common Issues

1. **IMDSv2 Token Not Available**
   ```bash
   # Check if IMDSv2 is enabled
   curl -X PUT "http://169.254.169.254/latest/api/token" \
     -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
   
   # If this fails, IMDSv2 might not be enabled
   # Fall back to IMDSv1
   curl http://169.254.169.254/latest/meta-data/instance-id
   ```

2. **AWS Authentication Fails**
   ```bash
   # Check IAM role attachment
   aws sts get-caller-identity
   
   # Verify instance profile
   aws iam get-instance-profile --instance-profile-name your-instance-profile
   ```

3. **SSM Parameter Access Denied**
   ```bash
   # Check SSM parameter permissions
   aws ssm describe-parameters --max-items 5
   
   # Verify parameter exists
   aws ssm get-parameter --name "/sandbox/go-mysql-api/db/password" --with-decryption
   ```

### Debugging Commands

```bash
# Check instance metadata (IMDSv2 secure)
./scripts/imdsv2-helper.sh instance-id
./scripts/imdsv2-helper.sh region
./scripts/imdsv2-helper.sh iam-role

# Check AWS CLI configuration
aws configure list
aws configure get default.region

# Test specific services
aws ssm describe-parameters --max-items 1
aws ecr get-authorization-token
aws logs describe-log-groups --max-items 1
```

## Security Best Practices

### 1. Token Management

- Use appropriate token TTL (default: 6 hours)
- Rotate tokens regularly
- Don't store tokens in plain text

### 2. IAM Permissions

- Follow principle of least privilege
- Use specific resource ARNs when possible
- Regularly audit IAM permissions

### 3. Network Security

- Use security groups to restrict access
- Enable VPC flow logs for monitoring
- Use private subnets for sensitive instances

### 4. Monitoring

- Monitor authentication failures
- Set up CloudWatch alarms for unusual activity
- Log all AWS API calls

## Integration with Ansible

The Ansible playbooks include IAMv2 authentication testing:

```yaml
- name: Test IAMv2 authentication
  hosts: go_mysql_api_instances
  tasks:
    - name: Test AWS authentication
      command: aws sts get-caller-identity
      register: auth_test
      
    - name: Display authentication result
      debug:
        msg: "AWS Authentication: {{ 'Success' if auth_test.rc == 0 else 'Failed' }}"
```

## Environment Variables

The following environment variables are automatically set:

```bash
export AWS_DEFAULT_REGION="us-east-1"  # From instance metadata
export AWS_PAGER=""
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

## Monitoring and Logging

### CloudWatch Logs

Application logs are automatically sent to CloudWatch:

- **Log Group**: `/aws/ec2/sandbox-go-mysql-api/application`
- **Log Stream**: `{instance-id}`
- **Retention**: 14 days

### Metrics

The following metrics are collected:

- CPU usage
- Memory usage
- Disk usage
- Application health checks

## Next Steps

1. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Test IAMv2 authentication**:
   ```bash
   ./test-iamv2-auth.sh
   ```

3. **Deploy the application**:
   ```bash
   ansible-playbook database-init.yml
   ```

4. **Monitor the deployment**:
   ```bash
   # Check CloudWatch logs
   aws logs tail /aws/ec2/sandbox-go-mysql-api/application --follow
   
   # Check application status
   curl http://your-instance-ip:8080/health
   ```

## Support

If you encounter issues with IAMv2 authentication:

1. Check the CloudInit logs: `/var/log/cloud-init-output.log`
2. Verify IAM role permissions
3. Test instance metadata access
4. Review CloudWatch logs for errors
5. Run the authentication test script

For additional help, refer to the AWS documentation on [Instance Metadata Service v2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).
