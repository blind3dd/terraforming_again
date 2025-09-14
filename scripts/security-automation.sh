#!/bin/bash

# Security Automation Script
# Follows Kubernetes and CAPI community standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SECURITY_SCAN_DIR="${SECURITY_SCAN_DIR:-.}"
OUTPUT_DIR="${OUTPUT_DIR:-security-reports}"
POLICY_DIR="${POLICY_DIR:-security/policies}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}🔒 Starting Automated Security Scanning${NC}"
echo "=================================="

# Function to run security scan
run_security_scan() {
    local scan_type="$1"
    local scan_command="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Running $scan_type scan...${NC}"
    
    if eval "$scan_command" > "$OUTPUT_DIR/$output_file" 2>&1; then
        echo -e "${GREEN}✅ $scan_type scan completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ $scan_type scan failed${NC}"
        return 1
    fi
}

# Function to check if tool is installed
check_tool() {
    local tool="$1"
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${YELLOW}⚠️  $tool not found, skipping related scans${NC}"
        return 1
    fi
    return 0
}

# 1. Vulnerability Scanning
echo -e "${BLUE}📋 Running Vulnerability Scans${NC}"

if check_tool "trivy"; then
    run_security_scan "Trivy Filesystem" \
        "trivy fs --format json --output trivy-fs.json $SECURITY_SCAN_DIR" \
        "trivy-fs.json"
    
    run_security_scan "Trivy Configuration" \
        "trivy config --format json --output trivy-config.json $SECURITY_SCAN_DIR" \
        "trivy-config.json"
fi

if check_tool "grype"; then
    run_security_scan "Grype" \
        "grype --output json --file grype-results.json $SECURITY_SCAN_DIR" \
        "grype-results.json"
fi

# 2. Infrastructure Security Scanning
echo -e "${BLUE}🏗️  Running Infrastructure Security Scans${NC}"

if check_tool "checkov"; then
    run_security_scan "Checkov Terraform" \
        "checkov -d $SECURITY_SCAN_DIR --framework terraform --output json --output-file-path $OUTPUT_DIR/checkov-terraform.json" \
        "checkov-terraform.json"
    
    run_security_scan "Checkov Kubernetes" \
        "checkov -d $SECURITY_SCAN_DIR --framework kubernetes --output json --output-file-path $OUTPUT_DIR/checkov-k8s.json" \
        "checkov-k8s.json"
    
    run_security_scan "Checkov Helm" \
        "checkov -d $SECURITY_SCAN_DIR --framework helm --output json --output-file-path $OUTPUT_DIR/checkov-helm.json" \
        "checkov-helm.json"
fi

# 3. Kubernetes Security Scanning
echo -e "${BLUE}☸️  Running Kubernetes Security Scans${NC}"

if check_tool "kube-score"; then
    find "$SECURITY_SCAN_DIR" -name "*.yaml" -o -name "*.yml" | while read -r file; do
        if grep -q "kind:" "$file"; then
            echo "Scanning $file with kube-score..."
            kube-score score "$file" --output-format json > "$OUTPUT_DIR/kube-score-$(basename "$file" .yaml).json" 2>&1 || true
        fi
    done
fi

if check_tool "polaris"; then
    run_security_scan "Polaris" \
        "polaris audit --audit-path $SECURITY_SCAN_DIR --format json --output-file $OUTPUT_DIR/polaris-results.json" \
        "polaris-results.json"
fi

# 4. Policy Validation
echo -e "${BLUE}📜 Running Policy Validation${NC}"

if check_tool "conftest"; then
    find "$SECURITY_SCAN_DIR" -name "*.yaml" -o -name "*.yml" | while read -r file; do
        if grep -q "kind:" "$file"; then
            echo "Validating $file with Conftest..."
            conftest test "$file" --policy "$POLICY_DIR/conftest" --output json > "$OUTPUT_DIR/conftest-$(basename "$file" .yaml).json" 2>&1 || true
        fi
    done
fi

if check_tool "kyverno"; then
    find "$SECURITY_SCAN_DIR" -name "*.yaml" -o -name "*.yml" | while read -r file; do
        if grep -q "kind:" "$file"; then
            echo "Validating $file with Kyverno..."
            kyverno apply "$file" --policy "$POLICY_DIR/kyverno" --output json > "$OUTPUT_DIR/kyverno-$(basename "$file" .yaml).json" 2>&1 || true
        fi
    done
fi

# 5. Secrets Detection
echo -e "${BLUE}🔐 Running Secrets Detection${NC}"

if check_tool "trufflehog"; then
    run_security_scan "TruffleHog" \
        "trufflehog filesystem --directory $SECURITY_SCAN_DIR --output json" \
        "trufflehog-results.json"
fi

if check_tool "gitleaks"; then
    run_security_scan "GitLeaks" \
        "gitleaks detect --source $SECURITY_SCAN_DIR --report-format json --report-path $OUTPUT_DIR/gitleaks-results.json" \
        "gitleaks-results.json"
fi

# 6. Code Security Scanning
echo -e "${BLUE}🔍 Running Code Security Scans${NC}"

if check_tool "semgrep"; then
    run_security_scan "Semgrep" \
        "semgrep --config=auto --json --output $OUTPUT_DIR/semgrep-results.json $SECURITY_SCAN_DIR" \
        "semgrep-results.json"
fi

if check_tool "bandit"; then
    find "$SECURITY_SCAN_DIR" -name "*.py" | while read -r file; do
        echo "Scanning $file with Bandit..."
        bandit -f json -o "$OUTPUT_DIR/bandit-$(basename "$file" .py).json" "$file" 2>&1 || true
    done
fi

if check_tool "gosec"; then
    find "$SECURITY_SCAN_DIR" -name "*.go" | head -1 | xargs dirname | while read -r dir; do
        if [ -n "$dir" ]; then
            echo "Scanning Go code in $dir with gosec..."
            gosec -fmt json -out "$OUTPUT_DIR/gosec-results.json" "$dir" 2>&1 || true
        fi
    done
fi

# 7. Compliance Scanning
echo -e "${BLUE}📋 Running Compliance Scans${NC}"

if check_tool "kube-bench"; then
    run_security_scan "CIS Kubernetes Benchmark" \
        "kube-bench run --targets policies --config-dir=cfg --config=config.yaml --json" \
        "cis-benchmark-results.json"
fi

# 8. Generate Security Report
echo -e "${BLUE}📊 Generating Security Report${NC}"

cat > "$OUTPUT_DIR/security-report.md" << EOF
# Security Scan Report

**Generated:** $(date)
**Repository:** ${GITHUB_REPOSITORY:-"local"}
**Branch:** ${GITHUB_REF_NAME:-"local"}
**Commit:** ${GITHUB_SHA:-"local"}

## Scan Summary

| Scan Type | Status | Output File |
|-----------|--------|-------------|
EOF

# Add scan results to report
for file in "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        echo "| ${basename_file%.json} | ✅ Completed | $basename_file |" >> "$OUTPUT_DIR/security-report.md"
    fi
done

cat >> "$OUTPUT_DIR/security-report.md" << EOF

## Security Tools Used

- **Trivy**: Vulnerability scanner for containers and filesystems
- **Grype**: Vulnerability scanner for container images
- **Checkov**: Infrastructure as Code security scanning
- **Kube-score**: Kubernetes object analysis
- **Polaris**: Kubernetes best practices validation
- **Conftest**: Policy validation using Open Policy Agent
- **Kyverno**: Kubernetes policy engine
- **TruffleHog**: Secrets detection
- **GitLeaks**: Git secrets detection
- **Semgrep**: Static analysis security testing
- **Bandit**: Python security linter
- **Gosec**: Go security checker
- **Kube-bench**: CIS Kubernetes benchmark

## Next Steps

1. Review all scan results in the output files
2. Address critical and high severity findings
3. Implement security policies in your cluster
4. Set up continuous security monitoring
5. Integrate security scanning into CI/CD pipeline

## Security Best Practices

- Run security scans on every pull request
- Implement admission controllers for policy enforcement
- Use network policies for micro-segmentation
- Enable audit logging
- Regular security updates and patches
- Implement least privilege access
- Use secrets management solutions
- Enable runtime security monitoring
EOF

echo -e "${GREEN}✅ Security scanning completed successfully${NC}"
echo -e "${BLUE}📁 Results saved to: $OUTPUT_DIR${NC}"
echo -e "${BLUE}📊 Security report: $OUTPUT_DIR/security-report.md${NC}"

# Exit with appropriate code
if [ -f "$OUTPUT_DIR"/*.json ]; then
    echo -e "${GREEN}🎉 Security automation completed successfully${NC}"
    exit 0
else
    echo -e "${RED}❌ No security scan results generated${NC}"
    exit 1
fi
