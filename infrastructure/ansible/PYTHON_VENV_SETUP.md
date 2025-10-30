# Python Virtual Environment Setup

This project uses Python virtual environments (venv) instead of pipenv for dependency management.

## Quick Setup

```bash
# Automated setup (recommended)
./setup-venv.sh

# Manual setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml
```

## Available Scripts

- `./setup-venv.sh` - Initial virtual environment setup
- `./activate-venv.sh` - Activate the virtual environment
- `./deactivate-venv.sh` - Deactivate the virtual environment
- `./setup-dev.sh` - Setup development environment
- `./quick-start.sh` - Quick start guide

## Requirements Files

- `requirements.txt` - Production dependencies
- `requirements-dev.txt` - Development dependencies
- `requirements.yml` - Ansible Galaxy collections

## Usage

```bash
# Activate environment
source venv/bin/activate

# Run Ansible playbooks
ansible-playbook playbooks/site.yml

# Deactivate when done
deactivate
```

## Why Python venv?

- **Standard library**: Built into Python 3.3+
- **Lightweight**: No additional tools required
- **Fast**: Quick activation and package installation
- **Compatible**: Works with all Python tools
- **Simple**: Easy to understand and maintain
