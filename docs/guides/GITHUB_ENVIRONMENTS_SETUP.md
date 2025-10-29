# GitHub Environments Setup Guide

## 🎯 Environment Strategy

We use **GitHub Environments** for:
- 🔐 Storing environment-specific secrets
- 🛡️ Deployment protection rules
- 📊 Deployment tracking

We use **the same IAM role** (`iacrole`) for all environments, with separation via:
- Terraform workspaces
- Resource tags
- GitHub protection rules

---

## 📋 Create GitHub Environments

### **1. Dev Environment**

**Settings → Environments → New environment**

**Name:** `dev`

**Secrets:**
```
AWS_ROLE_TO_ASSUME = arn:aws:iam::690248313240:role/iacrole
```

**Protection Rules:**
- ❌ Required reviewers: None
- ❌ Wait timer: None
- ✅ Deployment branches: Any branch

**Why:** Fast iteration, no approval needed

---

### **2. Test Environment**

**Name:** `test`

**Secrets:**
```
AWS_ROLE_TO_ASSUME = arn:aws:iam::690248313240:role/iacrole
```

**Protection Rules:**
- ❌ Required reviewers: None (or 1 for stricter control)
- ✅ Wait timer: 5 minutes (gives time to cancel)
- ✅ Deployment branches: `main`, `working_branch` only

**Why:** Slight protection, time to review before deploy

---

### **3. Prod Environment**

**Name:** `prod`

**Secrets:**
```
AWS_ROLE_TO_ASSUME = arn:aws:iam::987654321098:role/iacrole-prod
(Different AWS account when ready!)
```

**Protection Rules:**
- ✅ Required reviewers: 1 (must approve deployments)
- ✅ Wait timer: 10 minutes
- ✅ Deployment branches: `main` only

**Why:** Maximum protection, requires approval

---

## 🔐 Same IAM Role, Different Environments

### **How Separation Works:**

```
GitHub Workflow runs:
  ↓
Uses environment: 'dev'
  ↓
Loads secret: AWS_ROLE_TO_ASSUME (iacrole)
  ↓
Assumes role: arn:aws:iam::690248313240:role/iacrole
  ↓
Terraform workspace: 'dev'
  ↓
Creates resources with tag: Environment=dev
  ↓
Separate state: terraform.tfstate.d/dev/
```

### **Benefits:**

✅ **Simpler IAM management** - one role to maintain
✅ **Same permissions** across dev/test
✅ **Workspace isolation** - separate state files
✅ **Tag-based separation** - cost allocation, resource filtering
✅ **GitHub protection** - control who can deploy where

### **Trade-offs:**

⚠️ Dev and test share same AWS permissions
⚠️ A mistake in dev *could* affect test (if not careful with workspaces)

---

## 🎯 Current Environment Mapping

| GitHub Env | AWS Account | IAM Role | Terraform Workspace | Branch Restriction |
|------------|-------------|----------|---------------------|-------------------|
| **dev** | 690248313240 | iacrole | dev | Any branch |
| **test** | 690248313240 | iacrole | test | main, working_branch |
| **prod** | 987654321098 | iacrole-prod | prod | main only |

---

## 🔧 Environment Variables Flow

```
GitHub Environment (dev)
  └── Secret: AWS_ROLE_TO_ASSUME = ...iacrole
      ↓
Workflow assumes role
      ↓
Terraform workspace: dev
  └── Outputs: VPC, RDS, EC2 info
      ↓
Writes to: infrastructure/ansible/inventory/dev/hosts.yml
      ↓
Ansible reads inventory
  └── group_vars/dev.yml (from Terraform)
      ↓
Deploys ArgoCD Application
  └── Path: infrastructure/kubernetes/overlays/dev
      ↓
ArgoCD syncs manifests
  └── Namespace: dev
      ↓
Application runs in Kubernetes
```

---

## ✅ Quick Setup Commands

```bash
# 1. In GitHub UI, create environments: dev, test, prod

# 2. Add secrets to each environment:
# Settings → Environments → [env] → Add secret
# Name: AWS_ROLE_TO_ASSUME
# Value: arn:aws:iam::690248313240:role/iacrole

# 3. Configure protection rules per environment

# 4. Update workflow to use environments:
environment: dev  # or test, or prod
```

---

## 🚀 Testing the Setup

```bash
# Test that GitHub Actions can assume the role
gh workflow run ci-cd-pipeline.yml

# Check the workflow run
gh run list

# View logs
gh run view <run-id> --log
```

---

**Your current `iacrole` works perfectly for this setup!** No need to create separate roles. 🎉

