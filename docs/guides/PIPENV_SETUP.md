# Pipenv Setup for Dynamic Inventory

This project uses [pipenv](https://pipenv.pypa.io/) for Python dependency management, providing a more modern and reliable approach to managing Python packages.

## What is Pipenv?

Pipenv is a tool that combines pip (Python package installer) and virtualenv (virtual environment) into a single command-line tool. It automatically creates and manages a virtual environment for your project, as well as adds/removes packages from your `Pipfile` as you install/uninstall packages.

## Quick Start

### 1. Install Dependencies

Run the setup script to install pipenv and all dependencies:

```bash
./setup-pipenv.sh
```

This script will:
- Check for Python 3 installation
- Install pipenv if not already installed
- Install all dependencies from `Pipfile`
- Make the dynamic inventory script executable
- Test AWS credentials
- Test the dynamic inventory

### 2. Activate the Virtual Environment

```bash
pipenv shell
```

This activates the virtual environment and you'll see `(database_CI-...)` in your prompt.

### 3. Run Commands

All commands should be run within the virtual environment:

```bash
# Test connectivity to EC2 instances
pipenv run ansible webservers -m ping

# Run the database initialization playbook
pipenv run ansible-playbook database-init.yml

# List all discovered instances
pipenv run inventory-list

# Test specific host
pipenv run inventory-host i-1234567890abcdef0
```

## Project Structure

```
├── Pipfile                 # Dependency specifications
├── Pipfile.lock           # Locked dependency versions
├── ec2.py                 # Dynamic inventory script
├── ansible.cfg            # Ansible configuration
├── inventory              # Static inventory (for group definitions)
├── setup-pipenv.sh        # Setup script
└── requirements.txt       # Alternative requirements (for pip)
```

## Dependencies

### Production Dependencies

- **boto3/botocore**: AWS SDK for Python
- **ansible**: Infrastructure automation
- **requests**: HTTP library
- **pyyaml**: YAML parser
- **jinja2**: Template engine
- **cryptography**: Cryptographic recipes

### Development Dependencies

- **pytest**: Testing framework
- **black**: Code formatter
- **flake8**: Linter
- **mypy**: Type checker
- **pre-commit**: Git hooks
- **sphinx**: Documentation generator

## Convenience Scripts

The `Pipfile` includes several convenience scripts:

```bash
# Testing
pipenv run test              # Run pytest
pipenv run format            # Format code with black
pipenv run lint              # Lint code with flake8
pipenv run type-check        # Type check with mypy

# Inventory
pipenv run inventory-list    # List all instances
pipenv run inventory-host    # Get host variables

# Ansible
pipenv run ansible-ping      # Ping webservers
pipenv run ansible-playbook  # Run playbooks
```

## Dynamic Inventory

The dynamic inventory automatically discovers EC2 instances based on tags:

### Instance Groups

- **webservers**: All web server instances
- **go_mysql_api_instances**: Go MySQL API instances
- **env_[environment]**: Environment-specific groups
- **type_[instance_type]**: Instance type groups
- **az_[availability_zone]**: Availability zone groups

### Required Tags

For instances to be discovered, they should have these tags:

- `Service: go-mysql-api`
- `Environment: [environment-name]`

### Host Variables

Each instance automatically gets these variables:

- `ansible_host`: Public or private IP
- `private_ip`: Private IP address
- `public_ip`: Public IP address
- `instance_id`: EC2 instance ID
- `instance_type`: Instance type
- `availability_zone`: AZ
- `vpc_id`: VPC ID
- `subnet_id`: Subnet ID
- `state`: Instance state
- `tag_*`: All instance tags as variables

## Development Workflow

### 1. Adding New Dependencies

```bash
# Add production dependency
pipenv install package-name

# Add development dependency
pipenv install --dev package-name
```

### 2. Updating Dependencies

```bash
# Update all dependencies
pipenv update

# Update specific package
pipenv update package-name
```

### 3. Running Tests

```bash
# Run all tests
pipenv run test

# Run with coverage
pipenv run pytest --cov=.

# Run specific test file
pipenv run pytest test_file.py
```

### 4. Code Quality

```bash
# Format code
pipenv run format

# Check code quality
pipenv run lint

# Type checking
pipenv run type-check
```

## Troubleshooting

### Common Issues

1. **Pipenv not found**
   ```bash
   pip install pipenv
   ```

2. **Python version mismatch**
   ```bash
   pipenv --python 3.9
   ```

3. **AWS credentials not configured**
   ```bash
   aws configure
   ```

4. **Permission denied on inventory script**
   ```bash
   chmod +x ec2.py
   ```

### Virtual Environment Location

To find where your virtual environment is located:

```bash
pipenv --venv
```

### Removing Virtual Environment

To remove the virtual environment and start fresh:

```bash
pipenv --rm
```

## Migration from requirements.txt

If you were previously using `requirements.txt`, the setup script will handle the migration automatically. The `Pipfile` includes all the dependencies from `requirements.txt` plus additional development tools.

## Best Practices

1. **Always use pipenv shell** or `pipenv run` to ensure you're in the virtual environment
2. **Commit both Pipfile and Pipfile.lock** to version control
3. **Use the convenience scripts** for common tasks
4. **Run tests before committing** changes
5. **Keep dependencies up to date** regularly

## Integration with CI/CD

For CI/CD pipelines, you can install dependencies without creating a virtual environment:

```bash
pipenv install --deploy --ignore-pipfile
```

This ensures the exact versions from `Pipfile.lock` are installed.
