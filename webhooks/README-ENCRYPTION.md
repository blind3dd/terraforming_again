# API Compatibility Webhook - Enhanced Security

This enhanced version of the API Compatibility Webhook includes AES-GCM encryption for sensitive environment variables and optional Carlos-style configuration management.

## Security Features

### 🔐 AES-GCM Encryption
- **Algorithm**: AES-256-GCM with random nonces
- **Key Derivation**: SHA-256 hash of provided encryption key
- **Base64 Encoding**: Encrypted values are base64-encoded for safe storage
- **Backward Compatibility**: Supports both encrypted and plaintext values

### 🛡️ Secure Environment Variables
Sensitive environment variables are automatically encrypted/decrypted:
- `GITHUB_TOKEN` - GitHub personal access token
- Any variable marked with `secure:"true"` in Carlos config

### 🔍 Encryption Detection Methods
The webhook uses two methods to detect encrypted values:

1. **Explicit Marker**: Values prefixed with `ENC:` are treated as encrypted
   ```bash
   export GITHUB_TOKEN="ENC:base64_encrypted_value_here"
   ```

2. **Auto-Detection**: Attempts decryption first, falls back to plaintext if it fails
   ```bash
   export GITHUB_TOKEN="base64_encrypted_value_here"  # No prefix needed
   ```

This approach ensures:
- ✅ **No False Positives**: Plaintext tokens won't be incorrectly decrypted
- ✅ **Backward Compatibility**: Existing encrypted values work without changes
- ✅ **Explicit Control**: Use `ENC:` prefix for guaranteed encryption detection

## Usage

### 1. Basic Setup (Legacy Mode)

```bash
# Set encryption key (use a strong, unique key in production)
export ENCRYPTION_KEY="your-super-secret-encryption-key-here"

# Encrypt your GitHub token
go run encrypt-env.go "your-super-secret-encryption-key-here" "ghp_your_github_token_here"

# Set the encrypted token
export GITHUB_TOKEN="encrypted_base64_value_here"

# Run the webhook
go run api-compatibility-webhook.go
```

### 2. Carlos Configuration Mode

```bash
# Enable Carlos configuration
export USE_CARLOS_CONFIG="true"
export ENCRYPTION_KEY="your-super-secret-encryption-key-here"

# Set encrypted sensitive values
export GITHUB_TOKEN="encrypted_base64_value_here"

# Set other configuration (optional, will use defaults)
export PORT="8080"
export LOG_LEVEL="debug"
export MAX_CONCURRENCY="20"

# Run the webhook
go run api-compatibility-webhook.go config-carlos.go
```

### 3. Configuration File Mode

```bash
# Create configuration file
cp config-defaults.json my-config.json
# Edit my-config.json with your values

# Load from file
go run api-compatibility-webhook.go config-carlos.go -config=my-config.json
```

## Encryption Utility

### Encrypt Environment Variables

```bash
# Encrypt a GitHub token
go run encrypt-env.go "my-encryption-key" "ghp_xxxxxxxxxxxx"

# Output:
# Encrypted value: base64_encoded_encrypted_value
# 
# To use this in your environment:
# export ENCRYPTION_KEY='my-encryption-key'
# export GITHUB_TOKEN='base64_encoded_encrypted_value'
```

### Decrypt Environment Variables (for testing)

```go
// Example Go code to decrypt
package main

import (
    "fmt"
    "log"
)

func main() {
    encryptedEnv := NewEncryptedEnv("your-encryption-key")
    decrypted, err := encryptedEnv.Decrypt("your-encrypted-value")
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(decrypted)
}
```

## Carlos Configuration Structure

The Carlos-style configuration provides:

### Field Tags
- `env:"VAR_NAME"` - Environment variable name
- `default:"value"` - Default value if not set
- `encrypt:"true"` - Mark as sensitive (will be encrypted)
- `json:"field_name"` - JSON field name

### Encrypt Tag Usage
The `encrypt:"true"` tag automatically:
- ✅ **Encrypts/Decrypts**: Environment variables marked with this tag
- ✅ **Redacts in Logs**: Automatically hides values in JSON output
- ✅ **Validates**: Ensures encrypted fields are properly handled
- ✅ **Maps Environment**: Creates mapping between env vars and struct fields

### Supported Types
- `string` - Text values
- `int` - Integer values
- `bool` - Boolean values (true/false, 1/0, yes/no)

### Example Configuration

```go
type CarlosConfig struct {
    // Public configuration (not encrypted)
    Port              string `env:"PORT" default:"8080" json:"port"`
    Repository        string `env:"REPOSITORY" default:"blind3dd/database_CI" json:"repository"`
    WorkingDir        string `env:"WORKING_DIR" default:"/tmp/webhook-workspace" json:"working_dir"`
    KubernetesVersion string `env:"KUBERNETES_VERSION" default:"1.28" json:"kubernetes_version"`
    LogLevel          string `env:"LOG_LEVEL" default:"info" json:"log_level"`
    MaxConcurrency    int    `env:"MAX_CONCURRENCY" default:"10" json:"max_concurrency"`
    RequestTimeout    int    `env:"REQUEST_TIMEOUT" default:"30" json:"request_timeout"`
    EnableMetrics     bool   `env:"ENABLE_METRICS" default:"true" json:"enable_metrics"`
    MetricsPort       string `env:"METRICS_PORT" default:"9090" json:"metrics_port"`
    
    // Sensitive configuration (encrypted)
    GitHubToken       string `env:"GITHUB_TOKEN" encrypt:"true" json:"github_token"`
    EncryptionKey     string `env:"ENCRYPTION_KEY" encrypt:"true" json:"encryption_key"`
    DatabasePassword  string `env:"DATABASE_PASSWORD" encrypt:"true" json:"database_password"`
    APIKey           string `env:"API_KEY" encrypt:"true" json:"api_key"`
    SecretToken      string `env:"SECRET_TOKEN" encrypt:"true" json:"secret_token"`
}
```

## Security Best Practices

### 1. Encryption Key Management
```bash
# Generate a strong encryption key
openssl rand -base64 32

# Store securely (use a secret management system in production)
export ENCRYPTION_KEY="$(openssl rand -base64 32)"
```

### 2. Environment Variable Security
```bash
# Never log sensitive environment variables
export GITHUB_TOKEN="encrypted_value_here"

# Use process substitution to avoid shell history
export GITHUB_TOKEN="$(cat /path/to/encrypted/token)"
```

### 3. Container Security
```dockerfile
# In Dockerfile, use multi-stage build to avoid exposing secrets
FROM golang:1.21-alpine AS builder
# ... build steps ...

FROM alpine:latest
# Copy only the binary, not source code
COPY --from=builder /app/webhook /usr/local/bin/
# Don't copy config files with secrets
```

### 4. Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webhook-secrets
type: Opaque
data:
  encryption-key: <base64-encoded-encryption-key>
  github-token: <base64-encoded-encrypted-github-token>
```

## API Endpoints

### Health Check
```bash
curl http://localhost:8080/health
```

### API Compatibility Check
```bash
curl -X POST http://localhost:8080/api/compatibility \
  -H "Content-Type: application/json" \
  -d '{
    "event": "kustomize_change",
    "repository": "blind3dd/database_CI",
    "branch": "main",
    "commit": "abc123",
    "files": ["kustomize/go-mysql-api/overlays/dev/kustomization.yaml"]
  }'
```

## Monitoring and Logging

### Configuration Logging
- Configuration is logged at startup (with sensitive data redacted)
- Carlos config provides structured JSON logging
- Legacy mode provides basic configuration logging

### Security Logging
- Failed decryption attempts are logged as warnings
- Invalid encryption keys are logged as errors
- All sensitive data is automatically redacted from logs

## Troubleshooting

### Common Issues

1. **Decryption Failed**
   ```
   Warning: Failed to decrypt GITHUB_TOKEN, using default: cipher: message authentication failed
   ```
   - Check encryption key matches the one used to encrypt
   - Verify the encrypted value is valid base64

2. **Invalid Configuration**
   ```
   Configuration validation failed: GITHUB_TOKEN is required
   ```
   - Ensure GITHUB_TOKEN is set (encrypted or plaintext)
   - Check environment variable names match exactly

3. **Carlos Config Loading Failed**
   ```
   Failed to load Carlos configuration: error setting field GitHubToken: invalid integer value: abc
   ```
   - Check field types match environment variable values
   - Verify boolean values are true/false, 1/0, or yes/no

### Debug Mode
```bash
export LOG_LEVEL="debug"
export USE_CARLOS_CONFIG="true"
go run api-compatibility-webhook.go config-carlos.go
```

## Migration Guide

### From Plain Environment Variables
1. Set `ENCRYPTION_KEY`
2. Encrypt sensitive values using `encrypt-env.go`
3. Update environment variables with encrypted values
4. Test with `LOG_LEVEL="debug"`

### To Carlos Configuration
1. Set `USE_CARLOS_CONFIG="true"`
2. Optionally create custom configuration file
3. Update deployment scripts to use new environment variables
4. Test configuration loading and validation

## Production Deployment

### Docker Compose
```yaml
version: '3.8'
services:
  webhook:
    build: .
    environment:
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - USE_CARLOS_CONFIG=true
      - LOG_LEVEL=info
    ports:
      - "8080:8080"
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-compatibility-webhook
spec:
  template:
    spec:
      containers:
      - name: webhook
        image: your-registry/api-compatibility-webhook:latest
        env:
        - name: ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: webhook-secrets
              key: encryption-key
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: webhook-secrets
              key: github-token
        - name: USE_CARLOS_CONFIG
          value: "true"
```
