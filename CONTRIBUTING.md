# Contributing to terraforming_again

Welcome to the terraforming_again project! We're excited that you're interested in contributing. This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Community](#community)

## Code of Conduct

This project follows the [Kubernetes Code of Conduct](https://github.com/kubernetes/community/blob/master/CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## Getting Started

### Prerequisites

- Go 1.21+
- Terraform 1.5+
- Ansible 8.0+
- Helm 3.12+
- Kustomize 4.5+
- Docker
- kubectl
- Git

### Development Environment Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/your-username/terraforming_again.git
   cd terraforming_again
   ```

2. **Set up the development environment:**
   ```bash
   # Install dependencies
   make deps
   
   # Set up pre-commit hooks
   make setup-hooks
   
   # Run initial tests
   make test
   ```

3. **Configure your environment:**
   ```bash
   # Copy example configuration
   cp environments/shared/terraform.tfvars.example environments/shared/terraform.tfvars
   
   # Edit configuration with your values
   vim environments/shared/terraform.tfvars
   ```

## Development Workflow

### Branch Strategy

We follow the [GitHub Flow](https://guides.github.com/introduction/flow/) model:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Critical fixes

### Making Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow the coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes:**
   ```bash
   # Run all tests
   make test
   
   # Run specific test suites
   make test-terraform
   make test-ansible
   make test-helm
   make test-kustomize
   make test-go
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push and create a PR:**
   ```bash
   git push origin feature/your-feature-name
   ```

## Project Structure

```
terraforming_again/
├── applications/           # Application configurations
│   ├── go-mysql-api/      # Go MySQL API application
│   └── webhooks/          # Webhook services
├── operators/             # Kubernetes operators
│   ├── ansible-operator/  # Ansible operator
│   ├── terraform-operator/# Terraform operator
│   ├── vault-operator/    # Vault operator
│   └── karpenter/         # Karpenter operator
├── environments/          # Environment configurations
│   ├── dev/              # Development environment
│   ├── test/             # Test environment
│   ├── prod/             # Production environment
│   └── shared/           # Shared resources
├── infrastructure/        # Infrastructure components
│   ├── terraform/        # Terraform modules
│   ├── ansible/          # Ansible playbooks
│   └── scripts/          # Infrastructure scripts
├── ci-cd/                # CI/CD configurations
│   ├── github-actions/   # GitHub Actions workflows
│   ├── prow/             # Prow configurations
│   └── argocd/           # ArgoCD configurations
└── docs/                 # Documentation
```

## Testing

### Test Categories

- **Unit Tests** - Individual component testing
- **Integration Tests** - Component interaction testing
- **End-to-End Tests** - Full workflow testing
- **Security Tests** - Security vulnerability scanning
- **Performance Tests** - Performance benchmarking

### Running Tests

```bash
# Run all tests
make test

# Run specific test categories
make test-unit
make test-integration
make test-e2e
make test-security
make test-performance

# Run tests for specific components
make test-terraform
make test-ansible
make test-helm
make test-kustomize
make test-go
```

### Test Requirements

- All new code must have corresponding tests
- Test coverage should be >80%
- Tests must pass in CI/CD pipeline
- Security tests must pass before merge

## Submitting Changes

### Pull Request Process

1. **Create a Pull Request:**
   - Use the PR template
   - Link related issues
   - Add appropriate labels

2. **PR Requirements:**
   - All tests must pass
   - Code must be reviewed by at least 2 maintainers
   - Documentation must be updated
   - Security scan must pass

3. **Review Process:**
   - Maintainers will review your PR
   - Address feedback promptly
   - Keep PRs focused and small

4. **Merge Process:**
   - PRs are merged via "Squash and Merge"
   - Commit messages follow conventional commits
   - Release notes are automatically generated

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

**Examples:**
```
feat(webhooks): add API compatibility webhook
fix(terraform): resolve provider version conflict
docs(readme): update installation instructions
```

## Community

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General discussions and Q&A
- **Slack** - Real-time communication
- **Email** - Security issues and sensitive matters

### Getting Help

1. **Check existing issues and discussions**
2. **Search the documentation**
3. **Ask in Slack or GitHub Discussions**
4. **Create an issue if needed**

### Maintainers

- **Lead Maintainer**: [Your Name](https://github.com/your-username)
- **Infrastructure Maintainer**: [Name](https://github.com/username)
- **Security Maintainer**: [Name](https://github.com/username)

### Release Process

- **Releases** are made monthly
- **Security releases** are made as needed
- **Release notes** are automatically generated
- **Versioning** follows [Semantic Versioning](https://semver.org/)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Kubernetes Community
- Terraform Community
- Ansible Community
- All contributors and maintainers

---

Thank you for contributing to terraforming_again! 🎉
