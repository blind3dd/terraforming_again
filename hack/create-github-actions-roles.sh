#!/bin/bash
set -e

echo "🔧 Creating GitHub Actions IAM Roles per Environment"
echo "====================================================="
echo ""

AWS_ACCOUNT_ID="690248313240"
GITHUB_ORG="blind3dd"
GITHUB_REPO="terraforming_again"

# Create trust policy for all roles
cat > /tmp/github-actions-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

echo "📋 Step 1: Create Dev Role"
echo "============================"
cat > /tmp/github-actions-dev-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DevEnvironmentAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "s3:*",
        "dynamodb:*",
        "route53:*",
        "elasticloadbalancing:*",
        "iam:GetRole",
        "iam:PassRole",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    },
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-*",
        "arn:aws:s3:::terraform-state-*/*"
      ]
    },
    {
      "Sid": "TerraformLockAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT_ID}:table/terraform-locks"
    }
  ]
}
EOF

echo "aws iam create-role \\"
echo "  --role-name iacrole \\"
echo "  --assume-role-policy-document file:///tmp/github-actions-trust-policy.json"
echo ""
echo "aws iam put-role-policy \\"
echo "  --role-name iacrole \\"
echo "  --policy-name DevEnvironmentPolicy \\"
echo "  --policy-document file:///tmp/github-actions-dev-policy.json"
echo ""

echo "📋 Step 2: Create Test Role"
echo "============================="
cat > /tmp/github-actions-test-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TestEnvironmentAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "s3:*",
        "dynamodb:*",
        "route53:*",
        "elasticloadbalancing:*",
        "iam:GetRole",
        "iam:PassRole",
        "sts:GetCallerIdentity",
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    },
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-*",
        "arn:aws:s3:::terraform-state-*/*"
      ]
    },
    {
      "Sid": "TerraformLockAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT_ID}:table/terraform-locks"
    }
  ]
}
EOF

echo "aws iam create-role \\"
echo "  --role-name iacrole-test \\"
echo "  --assume-role-policy-document file:///tmp/github-actions-trust-policy.json"
echo ""
echo "aws iam put-role-policy \\"
echo "  --role-name iacrole-test \\"
echo "  --policy-name TestEnvironmentPolicy \\"
echo "  --policy-document file:///tmp/github-actions-test-policy.json"
echo ""

echo "📋 Step 3: Create Prod Role (Most Restrictive)"
echo "==============================================="
cat > /tmp/github-actions-prod-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProdEnvironmentReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "rds:Describe*",
        "s3:List*",
        "s3:Get*",
        "dynamodb:Describe*",
        "route53:Get*",
        "route53:List*",
        "elasticloadbalancing:Describe*",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ProdEnvironmentWriteWithApproval",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateTags",
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        "s3:PutObject",
        "dynamodb:PutItem",
        "route53:ChangeResourceRecordSets",
        "elasticloadbalancing:CreateLoadBalancer",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    },
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-prod",
        "arn:aws:s3:::terraform-state-prod/*"
      ]
    },
    {
      "Sid": "TerraformLockAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT_ID}:table/terraform-locks-prod"
    },
    {
      "Sid": "DenyDangerousActions",
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances",
        "rds:DeleteDBInstance",
        "s3:DeleteBucket",
        "dynamodb:DeleteTable"
      ],
      "Resource": "*"
    }
  ]
}
EOF

echo "aws iam create-role \\"
echo "  --role-name iacrole-prod \\"
echo "  --assume-role-policy-document file:///tmp/github-actions-trust-policy.json"
echo ""
echo "aws iam put-role-policy \\"
echo "  --role-name iacrole-prod \\"
echo "  --policy-name ProdEnvironmentPolicy \\"
echo "  --policy-document file:///tmp/github-actions-prod-policy.json"
echo ""

echo "📋 Step 4: Update GitHub Environment Secrets"
echo "=============================================="
echo ""
echo "Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/environments"
echo ""
echo "For each environment, set AWS_ROLE_TO_ASSUME:"
echo ""
echo "  dev environment:"
echo "    AWS_ROLE_TO_ASSUME = arn:aws:iam::${AWS_ACCOUNT_ID}:role/iacrole"
echo ""
echo "  test environment:"
echo "    AWS_ROLE_TO_ASSUME = arn:aws:iam::${AWS_ACCOUNT_ID}:role/iacrole-test"
echo ""
echo "  prod environment:"
echo "    AWS_ROLE_TO_ASSUME = arn:aws:iam::${AWS_ACCOUNT_ID}:role/iacrole-prod"
echo ""

echo "✅ Setup Complete!"
echo ""
echo "🎯 Quick Commands:"
echo "=================="
echo ""
echo "# Create all roles at once:"
echo "for env in Dev Test Prod; do"
echo "  aws iam create-role \\"
echo "    --role-name iacrole-\${env}-Role \\"
echo "    --assume-role-policy-document file:///tmp/github-actions-trust-policy.json"
echo "  aws iam put-role-policy \\"
echo "    --role-name iacrole-\${env}-Role \\"
echo "    --policy-name \${env}EnvironmentPolicy \\"
echo "    --policy-document file:///tmp/github-actions-\${env,,}-policy.json"
echo "done"
echo ""

