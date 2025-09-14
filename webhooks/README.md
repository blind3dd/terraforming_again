# API Compatibility Webhook

This webhook automatically detects Kubernetes API version changes in Kustomize and Helm configurations and updates Chart.yaml versions accordingly.

## Features

- **Automatic Detection**: Detects API version changes in Kustomize and Helm templates
- **Version Management**: Automatically updates Chart.yaml versions for compatibility
- **Deprecated API Detection**: Identifies deprecated Kubernetes API versions
- **Git Integration**: Commits and pushes version updates automatically
- **REST API**: Provides REST endpoints for manual compatibility checks
- **Health Monitoring**: Includes health check endpoints

## API Endpoints

### POST /webhook/api-compatibility
Main webhook endpoint for receiving webhook payloads.

**Request Body:**
```json
{
  "event": "push",
  "repository": "blind3dd/database_CI",
  "branch": "main",
  "commit": "abc123",
  "files": [
    "kustomize/go-mysql-api/overlays/dev/kustomization.yaml",
    "go-mysql-api/chart/templates/deployment.yaml"
  ],
  "metadata": {
    "kubernetes_version": "1.28"
  }
}
```

**Response:**
```json
{
  "success": true,
  "chart_version": "1.2.0",
  "new_chart_version": "1.3.0",
  "api_versions": [
    "apps/v1",
    "networking.k8s.io/v1",
    "autoscaling/v2"
  ],
  "deprecated_apis": [],
  "compatibility_issues": [],
  "message": "Chart version updated from 1.2.0 to 1.3.0 due to API compatibility changes",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### POST /api/compatibility/check
Direct API compatibility check endpoint.

**Request Body:**
```json
{
  "kubernetes_version": "1.28",
  "force_update": false,
  "files": [
    "kustomize/go-mysql-api/overlays/dev/kustomization.yaml"
  ],
  "repository": "blind3dd/database_CI",
  "branch": "main"
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Webhook server port | `8080` |
| `GITHUB_TOKEN` | GitHub personal access token | Required |
| `REPOSITORY` | Target repository | `blind3dd/database_CI` |
| `WORKING_DIR` | Working directory for git operations | `/tmp/webhook-workspace` |
| `KUBERNETES_VERSION` | Target Kubernetes version | `1.28` |

## Deployment

### Docker

```bash
# Build the image
docker build -t api-compatibility-webhook .

# Run the container
docker run -d \
  -p 8080:8080 \
  -e GITHUB_TOKEN=your_github_token \
  -e REPOSITORY=blind3dd/database_CI \
  -e KUBERNETES_VERSION=1.28 \
  api-compatibility-webhook
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-compatibility-webhook
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-compatibility-webhook
  template:
    metadata:
      labels:
        app: api-compatibility-webhook
    spec:
      containers:
      - name: webhook
        image: api-compatibility-webhook:latest
        ports:
        - containerPort: 8080
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-token
              key: token
        - name: REPOSITORY
          value: "blind3dd/database_CI"
        - name: KUBERNETES_VERSION
          value: "1.28"
---
apiVersion: v1
kind: Service
metadata:
  name: api-compatibility-webhook
spec:
  selector:
    app: api-compatibility-webhook
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

## Integration

### GitHub Actions

```yaml
- name: Trigger API Compatibility Check
  run: |
    curl -X POST http://webhook.example.com/webhook/api-compatibility \
      -H "Content-Type: application/json" \
      -d '{
        "event": "push",
        "repository": "blind3dd/database_CI",
        "branch": "main",
        "files": ["kustomize/go-mysql-api/overlays/dev/kustomization.yaml"]
      }'
```

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api-compatibility-webhook
spec:
  source:
    repoURL: https://github.com/blind3dd/database_CI.git
    path: webhooks
    helm:
      values: |
        service:
          type: ClusterIP
          port: 80
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          REPOSITORY: "blind3dd/database_CI"
          KUBERNETES_VERSION: "1.28"
```

## How It Works

1. **Webhook Trigger**: Receives webhook payload with changed files
2. **File Analysis**: Analyzes changed files for API version modifications
3. **Compatibility Check**: Checks for deprecated APIs and compatibility issues
4. **Version Update**: Updates Chart.yaml version if needed
5. **Git Operations**: Commits and pushes changes automatically
6. **Response**: Returns compatibility status and actions taken

## Supported API Versions

The webhook checks for compatibility with the following Kubernetes API versions:

- **apps/v1** - Deployments, StatefulSets, DaemonSets
- **networking.k8s.io/v1** - Ingress, NetworkPolicy
- **autoscaling/v2** - HorizontalPodAutoscaler
- **policy/v1** - PodDisruptionBudget
- **v1** - ConfigMap, Secret, Service

## Deprecated API Detection

The webhook automatically detects and flags the following deprecated APIs:

- `extensions/v1beta1` (deprecated in 1.16)
- `apps/v1beta1` (deprecated in 1.16)
- `apps/v1beta2` (deprecated in 1.16)
- `networking.k8s.io/v1beta1` (deprecated in 1.19)
- `autoscaling/v2beta1` (deprecated in 1.23)
- `autoscaling/v2beta2` (deprecated in 1.23)
- `policy/v1beta1` (deprecated in 1.21)

## Monitoring

The webhook provides comprehensive logging and monitoring:

- **Structured Logging**: All operations are logged with timestamps
- **Health Checks**: Built-in health check endpoint
- **Error Handling**: Graceful error handling with detailed error messages
- **Metrics**: Request/response metrics for monitoring

## Security

- **Token Authentication**: Uses GitHub personal access tokens
- **CORS Support**: Configurable CORS headers
- **Input Validation**: Validates all incoming requests
- **Error Sanitization**: Sanitizes error messages to prevent information leakage

