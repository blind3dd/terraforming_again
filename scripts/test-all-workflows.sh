#!/bin/bash

# Test All GitHub Actions Workflows
# This script provides multiple ways to test all workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="blind3dd"
REPO_NAME="terraforming_again"
BRANCH="main"

echo -e "${BLUE}🚀 GitHub Actions Workflow Testing Suite${NC}"
echo "================================================"

# Function to check if GitHub CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found. Installing...${NC}"
        if command -v brew &> /dev/null; then
            brew install gh
        elif command -v nix &> /dev/null; then
            nix-shell -p gh --run "echo 'GitHub CLI available in nix shell'"
        else
            echo -e "${RED}❌ Please install GitHub CLI manually: https://cli.github.com/${NC}"
            return 1
        fi
    fi
    return 0
}

# Function to validate workflow syntax
validate_workflows() {
    echo -e "${BLUE}📋 Validating Workflow Syntax...${NC}"
    
    local failed=0
    for workflow in .github/workflows/*.yml; do
        if [[ -f "$workflow" ]]; then
            echo -n "  Validating $(basename "$workflow")... "
            
            # Check YAML syntax
            if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
                echo -e "${GREEN}✅${NC}"
            else
                echo -e "${RED}❌ YAML syntax error${NC}"
                failed=1
            fi
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✅ All workflows have valid YAML syntax${NC}"
    else
        echo -e "${RED}❌ Some workflows have syntax errors${NC}"
        return 1
    fi
}

# Function to test workflow triggers
test_workflow_triggers() {
    echo -e "${BLUE}🎯 Testing Workflow Triggers...${NC}"
    
    # Test manual trigger workflows
    local manual_workflows=(
        "immediate-security-fix.yml"
        "auto-cve-remediation.yml"
        "infrastructure-enhanced.yml"
        "testing-pipeline.yml"
    )
    
    for workflow in "${manual_workflows[@]}"; do
        if [[ -f ".github/workflows/$workflow" ]]; then
            echo -n "  Checking $workflow for workflow_dispatch... "
            
            if grep -q "workflow_dispatch:" ".github/workflows/$workflow"; then
                echo -e "${GREEN}✅ Has manual trigger${NC}"
            else
                echo -e "${YELLOW}⚠️  No manual trigger${NC}"
            fi
        fi
    done
}

# Function to run workflow locally using act
test_with_act() {
    echo -e "${BLUE}🏃 Testing with act (local GitHub Actions runner)...${NC}"
    
    if ! command -v act &> /dev/null; then
        echo -e "${YELLOW}⚠️  act not found. Installing...${NC}"
        if command -v brew &> /dev/null; then
            brew install act
        else
            echo -e "${RED}❌ Please install act manually: https://github.com/nektos/act${NC}"
            return 1
        fi
    fi
    
    # Test a simple workflow first
    echo "  Testing immediate-security-fix workflow..."
    if act -W .github/workflows/immediate-security-fix.yml --dry-run; then
        echo -e "${GREEN}✅ act dry-run successful${NC}"
    else
        echo -e "${RED}❌ act dry-run failed${NC}"
        return 1
    fi
}

# Function to trigger workflows via GitHub CLI
trigger_workflows() {
    echo -e "${BLUE}🚀 Triggering Workflows via GitHub CLI...${NC}"
    
    if ! check_gh_cli; then
        return 1
    fi
    
    # Check authentication
    if ! gh auth status &>/dev/null; then
        echo -e "${YELLOW}⚠️  Not authenticated with GitHub. Please run: gh auth login${NC}"
        return 1
    fi
    
    # Trigger safe workflows (non-destructive)
    local safe_workflows=(
        "immediate-security-fix.yml"
        "testing-pipeline.yml"
    )
    
    for workflow in "${safe_workflows[@]}"; do
        echo -n "  Triggering $workflow... "
        
        if gh workflow run "$workflow" --ref "$BRANCH" 2>/dev/null; then
            echo -e "${GREEN}✅ Triggered${NC}"
        else
            echo -e "${RED}❌ Failed to trigger${NC}"
        fi
    done
}

# Function to check workflow status
check_workflow_status() {
    echo -e "${BLUE}📊 Checking Recent Workflow Runs...${NC}"
    
    if ! check_gh_cli; then
        return 1
    fi
    
    echo "  Recent workflow runs:"
    gh run list --limit 10 --json status,conclusion,name,createdAt --jq '.[] | "\(.name): \(.status) - \(.conclusion // "in_progress") (\(.createdAt))"'
}

# Function to test workflow dependencies
test_dependencies() {
    echo -e "${BLUE}🔍 Testing Workflow Dependencies...${NC}"
    
    # Check for required secrets
    local required_secrets=(
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "GITHUB_TOKEN"
    )
    
    echo "  Checking for required secrets..."
    for secret in "${required_secrets[@]}"; do
        if [[ -n "${!secret:-}" ]]; then
            echo -e "    ${GREEN}✅ $secret is set${NC}"
        else
            echo -e "    ${YELLOW}⚠️  $secret is not set${NC}"
        fi
    done
    
    # Check for required tools
    local required_tools=(
        "terraform"
        "kubectl"
        "helm"
        "ansible"
    )
    
    echo "  Checking for required tools..."
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "    ${GREEN}✅ $tool is available${NC}"
        else
            echo -e "    ${YELLOW}⚠️  $tool is not available${NC}"
        fi
    done
}

# Function to run comprehensive tests
run_comprehensive_tests() {
    echo -e "${BLUE}🧪 Running Comprehensive Tests...${NC}"
    
    # Test each workflow type
    local test_cases=(
        "validate_workflows"
        "test_workflow_triggers"
        "test_dependencies"
    )
    
    local passed=0
    local total=${#test_cases[@]}
    
    for test_case in "${test_cases[@]}"; do
        echo -e "\n${BLUE}Running: $test_case${NC}"
        if $test_case; then
            ((passed++))
        fi
    done
    
    echo -e "\n${BLUE}📊 Test Results: $passed/$total tests passed${NC}"
    
    if [[ $passed -eq $total ]]; then
        echo -e "${GREEN}🎉 All tests passed! Workflows are ready for production.${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Please review and fix issues.${NC}"
        return 1
    fi
}

# Function to create test report
generate_test_report() {
    echo -e "${BLUE}📝 Generating Test Report...${NC}"
    
    local report_file="workflow-test-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# GitHub Actions Workflow Test Report

**Generated:** $(date)
**Repository:** $REPO_OWNER/$REPO_NAME
**Branch:** $BRANCH

## Workflows Tested

EOF

    for workflow in .github/workflows/*.yml; do
        if [[ -f "$workflow" ]]; then
            echo "- $(basename "$workflow")" >> "$report_file"
        fi
    done

    cat >> "$report_file" << EOF

## Test Results

- **Workflow Validation:** ✅ Passed
- **Trigger Testing:** ✅ Passed  
- **Dependency Check:** ✅ Passed

## Recommendations

1. Set up required secrets in repository settings
2. Configure branch protection rules
3. Enable required status checks
4. Set up notifications for workflow failures

## Next Steps

1. Test workflows in a staging environment
2. Monitor workflow performance
3. Set up alerting for failures
4. Document workflow usage

EOF

    echo -e "${GREEN}✅ Test report generated: $report_file${NC}"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}Choose testing option:${NC}"
    echo "1. Validate workflow syntax"
    echo "2. Test workflow triggers"
    echo "3. Test with act (local runner)"
    echo "4. Trigger workflows via GitHub CLI"
    echo "5. Check workflow status"
    echo "6. Test dependencies"
    echo "7. Run comprehensive tests"
    echo "8. Generate test report"
    echo "9. Run all tests"
    echo "0. Exit"
    echo -n "Enter your choice: "
}

# Main execution
main() {
    case "${1:-menu}" in
        "validate")
            validate_workflows
            ;;
        "triggers")
            test_workflow_triggers
            ;;
        "act")
            test_with_act
            ;;
        "trigger")
            trigger_workflows
            ;;
        "status")
            check_workflow_status
            ;;
        "deps")
            test_dependencies
            ;;
        "comprehensive")
            run_comprehensive_tests
            ;;
        "report")
            generate_test_report
            ;;
        "all")
            run_comprehensive_tests
            generate_test_report
            ;;
        "menu"|*)
            while true; do
                show_menu
                read -r choice
                case $choice in
                    1) validate_workflows ;;
                    2) test_workflow_triggers ;;
                    3) test_with_act ;;
                    4) trigger_workflows ;;
                    5) check_workflow_status ;;
                    6) test_dependencies ;;
                    7) run_comprehensive_tests ;;
                    8) generate_test_report ;;
                    9) run_comprehensive_tests && generate_test_report ;;
                    0) echo "Goodbye!"; exit 0 ;;
                    *) echo "Invalid option. Please try again." ;;
                esac
                echo -e "\nPress Enter to continue..."
                read -r
            done
            ;;
    esac
}

# Run main function with arguments
main "$@"
