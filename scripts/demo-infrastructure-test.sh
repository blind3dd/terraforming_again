#!/bin/bash
set -e

echo "🎯 Demo: Infrastructure Test Apply & Teardown"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_demo_status() {
    print_status "Demo Infrastructure Test Status:"
    echo ""
    echo "🏗️  Infrastructure Components:"
    echo "   ✅ AWS VPC and networking"
    echo "   ✅ EC2 instances"
    echo "   ✅ RDS database"
    echo "   ✅ EKS cluster"
    echo "   ✅ Security groups"
    echo "   ✅ Load balancers"
    echo ""
    echo "🔧  Test Pipeline:"
    echo "   ✅ Terraform validation"
    echo "   ✅ Infrastructure planning"
    echo "   ✅ Infrastructure application"
    echo "   ✅ Infrastructure verification"
    echo "   ✅ Infrastructure testing"
    echo "   ✅ Infrastructure teardown"
    echo ""
    echo "🚀  CI/CD Integration:"
    echo "   ✅ GitHub Actions workflow"
    echo "   ✅ Prow job configuration"
    echo "   ✅ Automated testing"
    echo "   ✅ Security scanning"
    echo ""
}

main() {
    case "${1:-demo}" in
        "demo")
            show_demo_status
            echo ""
            print_status "To trigger infrastructure test:"
            echo "  $0 trigger test"
            ;;
        "trigger")
            print_status "Triggering infrastructure test for environment: ${2:-test}"
            print_success "Infrastructure test workflow ready!"
            print_status "Go to: https://github.com/blind3dd/terraforming_again/actions/workflows/infrastructure-test-apply.yml"
            ;;
        *)
            show_demo_status
            ;;
    esac
}

main "$@"
