#!/bin/bash
# Setup Python Virtual Environment for Ansible
# This script creates and configures a Python venv for the Database CI Infrastructure

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"; exit 1; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"; }

# Configuration
VENV_DIR="venv"
PYTHON_VERSION="3.9"
REQUIREMENTS_FILE="requirements.txt"
DEV_REQUIREMENTS_FILE="requirements-dev.txt"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    error "Python 3 is not installed. Please install Python 3.9 or later."
fi

# Check Python version
PYTHON_VER=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VER="3.9"

if [ "$(printf '%s\n' "$REQUIRED_VER" "$PYTHON_VER" | sort -V | head -n1)" != "$REQUIRED_VER" ]; then
    error "Python $REQUIRED_VER or later is required. Found: $PYTHON_VER"
fi

log "Setting up Python virtual environment for Ansible..."

# Remove existing venv if it exists
if [[ -d "$VENV_DIR" ]]; then
    warn "Existing virtual environment found. Removing it..."
    rm -rf "$VENV_DIR"
fi

# Create virtual environment
log "Creating virtual environment with Python $PYTHON_VER..."
python3 -m venv "$VENV_DIR"

# Activate virtual environment
log "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip
log "Upgrading pip..."
pip install --upgrade pip

# Install wheel
log "Installing wheel..."
pip install wheel

# Install requirements
if [[ -f "$REQUIREMENTS_FILE" ]]; then
    log "Installing production requirements..."
    pip install -r "$REQUIREMENTS_FILE"
else
    warn "Requirements file not found: $REQUIREMENTS_FILE"
fi

# Install Ansible Galaxy collections
log "Installing Ansible Galaxy collections..."
if [[ -f "requirements.yml" ]]; then
    ansible-galaxy install -r requirements.yml
else
    warn "Ansible Galaxy requirements file not found: requirements.yml"
fi

# Verify installation
log "Verifying installation..."
python --version
pip --version
ansible --version

# Display installed packages
log "Installed packages:"
pip list

# Create activation script
log "Creating activation script..."
cat > activate-venv.sh << 'EOF'
#!/bin/bash
# Activate Python virtual environment for Ansible

if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
    echo "Virtual environment activated!"
    echo "Python: $(python --version)"
    echo "Ansible: $(ansible --version | head -n1)"
    echo ""
    echo "Available commands:"
    echo "  ansible-playbook playbooks/site.yml"
    echo "  ansible-playbook playbooks/compile-selinux-policies.yml"
    echo "  ansible-playbook playbooks/secure-macos-k8s.yml"
    echo "  ansible-playbook playbooks/setup-k8s-seccomp-profiles.yml"
    echo "  ansible-playbook playbooks/install-aws-iam-authenticator.yml"
    echo "  ansible-playbook playbooks/istio-ambient-rds-deployment.yml"
    echo "  ansible-playbook playbooks/aws-resource-audit.yml"
    echo ""
    echo "To deactivate, run: deactivate"
else
    echo "Virtual environment not found. Run ./setup-venv.sh first."
    exit 1
fi
EOF

chmod +x activate-venv.sh

# Create deactivation script
log "Creating deactivation script..."
cat > deactivate-venv.sh << 'EOF'
#!/bin/bash
# Deactivate Python virtual environment

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    deactivate
    echo "Virtual environment deactivated."
else
    echo "No virtual environment is currently active."
fi
EOF

chmod +x deactivate-venv.sh

# Create development setup script
log "Creating development setup script..."
cat > setup-dev.sh << 'EOF'
#!/bin/bash
# Setup development environment

if [[ ! -f "venv/bin/activate" ]]; then
    echo "Virtual environment not found. Run ./setup-venv.sh first."
    exit 1
fi

source venv/bin/activate

echo "Installing development requirements..."
if [[ -f "requirements-dev.txt" ]]; then
    pip install -r requirements-dev.txt
else
    echo "Development requirements file not found: requirements-dev.txt"
    exit 1
fi

echo "Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
else
    echo "pre-commit not installed. Install development requirements first."
fi

echo "Development environment setup complete!"
echo "Run 'source venv/bin/activate' to activate the environment."
EOF

chmod +x setup-dev.sh

# Create quick start script
log "Creating quick start script..."
cat > quick-start.sh << 'EOF'
#!/bin/bash
# Quick start script for Database CI Infrastructure

set -euo pipefail

echo "========================================"
echo "Database CI Infrastructure - Quick Start"
echo "========================================"

# Check if virtual environment exists
if [[ ! -f "venv/bin/activate" ]]; then
    echo "Virtual environment not found. Setting up..."
    ./setup-venv.sh
fi

# Activate virtual environment
source venv/bin/activate

echo "Virtual environment activated!"
echo ""

# Check if Ansible collections are installed
if ! ansible-galaxy collection list | grep -q "kubernetes.core"; then
    echo "Installing Ansible Galaxy collections..."
    ansible-galaxy install -r requirements.yml
fi

echo "Ready to run Ansible playbooks!"
echo ""
echo "Available commands:"
echo "  ansible-playbook playbooks/site.yml                    # Complete infrastructure setup"
echo "  ansible-playbook playbooks/compile-selinux-policies.yml # SELinux policies"
echo "  ansible-playbook playbooks/secure-macos-k8s.yml        # macOS K8s security"
echo "  ansible-playbook playbooks/setup-k8s-seccomp-profiles.yml # Seccomp profiles"
echo "  ansible-playbook playbooks/install-aws-iam-authenticator.yml # AWS IAM Authenticator"
echo "  ansible-playbook playbooks/istio-ambient-rds-deployment.yml # Istio ambient RDS app"
echo "  ansible-playbook playbooks/aws-resource-audit.yml      # AWS resource audit"
echo ""
echo "Example:"
echo "  ansible-playbook playbooks/site.yml --check --diff     # Dry run"
echo "  ansible-playbook playbooks/site.yml -vvv               # Verbose output"
echo ""
echo "========================================"
EOF

chmod +x quick-start.sh

# Display completion message
log "Python virtual environment setup complete!"
info "Virtual environment created in: $VENV_DIR"
info "Python version: $(python --version)"
info "Ansible version: $(ansible --version | head -n1)"

echo ""
echo "========================================"
echo "Next steps:"
echo "========================================"
echo "1. Activate the virtual environment:"
echo "   source venv/bin/activate"
echo "   # or"
echo "   ./activate-venv.sh"
echo ""
echo "2. Run Ansible playbooks:"
echo "   ansible-playbook playbooks/site.yml"
echo "   # or"
echo "   ./quick-start.sh"
echo ""
echo "3. For development setup:"
echo "   ./setup-dev.sh"
echo ""
echo "4. To deactivate:"
echo "   deactivate"
echo "   # or"
echo "   ./deactivate-venv.sh"
echo "========================================"
