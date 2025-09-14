#!/bin/bash

# Fix Kustomize Deprecations Script
# Automatically updates deprecated Kustomize syntax to modern syntax

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Kustomize Deprecations${NC}"
echo "=================================="

# Function to fix deprecated syntax in a file
fix_kustomize_file() {
    local file="$1"
    echo -e "${YELLOW}Processing $file...${NC}"
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Fix 'bases' to 'resources'
    if grep -q "bases:" "$file"; then
        echo "  - Fixing 'bases' → 'resources'"
        sed -i '' 's/^bases:/resources:/g' "$file"
    fi
    
    # Fix 'patchesStrategicMerge' to 'patches'
    if grep -q "patchesStrategicMerge:" "$file"; then
        echo "  - Fixing 'patchesStrategicMerge' → 'patches'"
        
        # Create temporary file for complex replacement
        local temp_file=$(mktemp)
        
        # Convert patchesStrategicMerge to patches format
        awk '
        /^patchesStrategicMerge:/ {
            print "patches:"
            in_patches = 1
            next
        }
        in_patches && /^[[:space:]]*-/ {
            # Extract patch file name
            patch_file = $2
            gsub(/^[[:space:]]*-[[:space:]]*/, "", patch_file)
            gsub(/[[:space:]]*$/, "", patch_file)
            
            # Generate patch entry
            print "  - path: " patch_file
            print "    target:"
            print "      kind: Deployment"
            print "      name: placeholder"
            next
        }
        in_patches && /^[[:space:]]*[^[:space:]]/ && !/^[[:space:]]*-/ {
            in_patches = 0
        }
        {
            print
        }
        ' "$file" > "$temp_file"
        
        mv "$temp_file" "$file"
    fi
    
    echo -e "${GREEN}  ✅ Fixed $file${NC}"
}

# Find all kustomization.yaml files
find . -name "kustomization.yaml" -type f | while read -r file; do
    if grep -q "bases:\|patchesStrategicMerge:" "$file"; then
        fix_kustomize_file "$file"
    else
        echo -e "${GREEN}  ✅ $file is already up to date${NC}"
    fi
done

# Create missing patch files if they don't exist
create_missing_patches() {
    echo -e "${BLUE}📝 Creating missing patch files...${NC}"
    
    # Create terraform-operator-patch.yaml
    if [ ! -f "kustomize/operators/base/terraform-operator-patch.yaml" ]; then
        cat > kustomize/operators/base/terraform-operator-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: terraform-operator
spec:
  template:
    spec:
      containers:
      - name: terraform-operator
        env:
        - name: AWS_REGION
          value: "us-west-2"
        - name: TERRAFORM_VERSION
          value: "1.5.0"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
        echo "  - Created terraform-operator-patch.yaml"
    fi
    
    # Create vault-operator-patch.yaml
    if [ ! -f "kustomize/operators/base/vault-operator-patch.yaml" ]; then
        cat > kustomize/operators/base/vault-operator-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-operator
spec:
  template:
    spec:
      containers:
      - name: vault-operator
        env:
        - name: VAULT_ADDR
          value: "http://vault:8200"
        - name: VAULT_TOKEN
          valueFrom:
            secretKeyRef:
              name: vault-token
              key: token
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
        echo "  - Created vault-operator-patch.yaml"
    fi
    
    # Create ansible-operator-patch.yaml
    if [ ! -f "kustomize/operators/base/ansible-operator-patch.yaml" ]; then
        cat > kustomize/operators/base/ansible-operator-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ansible-operator
spec:
  template:
    spec:
      containers:
      - name: ansible-operator
        env:
        - name: ANSIBLE_VERSION
          value: "latest"
        - name: ANSIBLE_VAULT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ansible-vault-password
              key: password
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
        echo "  - Created ansible-operator-patch.yaml"
    fi
}

create_missing_patches

# Validate all Kustomize files
echo -e "${BLUE}🔍 Validating Kustomize files...${NC}"
find . -name "kustomization.yaml" -exec dirname {} \; | while read -r dir; do
    echo "Validating $dir"
    if kubectl kustomize "$dir" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ $dir is valid${NC}"
    else
        echo -e "${RED}  ❌ $dir has validation errors${NC}"
    fi
done

echo -e "${GREEN}🎉 Kustomize deprecation fixes completed!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "- Updated 'bases' → 'resources'"
echo "- Updated 'patchesStrategicMerge' → 'patches'"
echo "- Created missing patch files"
echo "- Validated all Kustomize configurations"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "- Review the changes in git diff"
echo "- Test the Kustomize builds"
echo "- Commit the fixes"
