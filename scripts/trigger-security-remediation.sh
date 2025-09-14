#!/bin/bash

# Trigger Security Remediation Script
# This script triggers the automated security remediation by making a small change

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Triggering Automated Security Remediation${NC}"
echo "=============================================="

# Function to update Go dependencies
update_go_dependencies() {
    echo -e "${YELLOW}📦 Updating Go dependencies...${NC}"
    
    if [ -f "go-mysql-api/go.mod" ]; then
        cd go-mysql-api
        
        # Update all dependencies to latest versions
        nix-shell -p go --run "go get -u ./..."
        nix-shell -p go --run "go get -u github.com/go-sql-driver/mysql@latest"
        nix-shell -p go --run "go get -u github.com/gorilla/mux@latest"
        nix-shell -p go --run "go get -u github.com/stretchr/testify@latest"
        nix-shell -p go --run "go get -u github.com/caarlos0/env@latest"
        nix-shell -p go --run "go get -u gopkg.in/yaml.v3@latest"
        
        # Clean up and verify
        nix-shell -p go --run "go mod tidy"
        nix-shell -p go --run "go mod verify"
        nix-shell -p go --run "go mod download"
        
        cd ..
        echo -e "${GREEN}✅ Go dependencies updated${NC}"
    else
        echo -e "${YELLOW}⚠️ No go-mysql-api directory found${NC}"
    fi
}

# Function to update Docker base images
update_docker_images() {
    echo -e "${YELLOW}🐳 Updating Docker base images...${NC}"
    
    find . -name "Dockerfile*" -type f | while read dockerfile; do
        echo "Updating $dockerfile..."
        
        # Update to latest secure versions
        sed -i '' 's/FROM golang:[0-9.]*-alpine[0-9.]*/FROM golang:1.21.5-alpine3.19/g' "$dockerfile"
        sed -i '' 's/FROM alpine:[0-9.]*/FROM alpine:3.19/g' "$dockerfile"
        sed -i '' 's/FROM ubuntu:[0-9.]*/FROM ubuntu:22.04/g' "$dockerfile"
        
        # Add security updates
        if grep -q "RUN apk add" "$dockerfile"; then
            sed -i '' 's/RUN apk add --no-cache/RUN apk add --no-cache \&\& apk upgrade --no-cache/g' "$dockerfile"
        fi
        
        echo -e "${GREEN}✅ Updated $dockerfile${NC}"
    done
}

# Function to update Python dependencies
update_python_dependencies() {
    echo -e "${YELLOW}🐍 Updating Python dependencies...${NC}"
    
    if [ -f "requirements.txt" ]; then
        # Update to latest secure versions
        sed -i '' 's/ansible==[0-9.]*/ansible==9.0.0/g' requirements.txt
        sed -i '' 's/ansible-lint==[0-9.]*/ansible-lint==24.0.0/g' requirements.txt
        sed -i '' 's/bandit==[0-9.]*/bandit==1.7.5/g' requirements.txt
        sed -i '' 's/safety==[0-9.]*/safety==3.0.1/g' requirements.txt
        
        echo -e "${GREEN}✅ Python dependencies updated${NC}"
    else
        echo -e "${YELLOW}⚠️ No requirements.txt found${NC}"
    fi
}

# Function to create a trigger file
create_trigger() {
    echo -e "${YELLOW}⚡ Creating remediation trigger...${NC}"
    
    # Create a timestamp file to trigger the workflow
    echo "# Security Remediation Trigger" > security-remediation-trigger.md
    echo "**Triggered:** $(date)" >> security-remediation-trigger.md
    echo "**Purpose:** Force security remediation workflow to run" >> security-remediation-trigger.md
    echo "**Status:** Active" >> security-remediation-trigger.md
    
    echo -e "${GREEN}✅ Trigger file created${NC}"
}

# Main execution
echo -e "${BLUE}🔧 Starting immediate security remediation...${NC}"

# Update dependencies
update_go_dependencies
update_docker_images
update_python_dependencies

# Create trigger
create_trigger

# Commit and push changes
echo -e "${YELLOW}📝 Committing security remediation changes...${NC}"

~/.nix-profile/bin/git add .
~/.nix-profile/bin/git commit --no-gpg-sign -m "security: trigger automated remediation

- Updated Go dependencies to latest secure versions
- Updated Docker base images to latest secure versions  
- Updated Python dependencies to latest secure versions
- Created remediation trigger file

This commit triggers the automated security remediation workflow
to address remaining Trivy alerts and security vulnerabilities."

~/.nix-profile/bin/git push origin working_branch

echo -e "${GREEN}🎉 Security remediation triggered successfully!${NC}"
echo ""
echo -e "${BLUE}📊 What happens next:${NC}"
echo "1. GitHub Actions will detect the push"
echo "2. Security remediation workflow will run"
echo "3. Automated fixes will be applied"
echo "4. New PRs will be created with security fixes"
echo "5. Trivy alerts should decrease"
echo ""
echo -e "${YELLOW}⏱️ Check GitHub Actions in a few minutes to see the remediation in progress${NC}"
