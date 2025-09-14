# Go MySQL API Helm Chart

A Helm chart for deploying the Go MySQL API application to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Docker image built and pushed to ECR

## Quick Start

1. **Build and push the Docker image to ECR:**
   ```bash
   cd go-mysql-api
   ./build-and-push-ecr.sh latest
   ```

2. **Install the chart:**
   ```bash
   helm install go-mysql-api ./chart \
     --set image.repository=<ECR_REPOSITORY_URL> \
     --set image.tag=latest \
     --set env.DB_HOST=<RDS_ENDPOINT> \
     --set env.DB_PASSWORD=<DB_PASSWORD>
   ```

3. **Access the application:**
   ```bash
   kubectl port-forward svc/go-mysql-api 8088:8088
   curl http://localhost:8088/health
   ```

## Configuration

The following table lists the configurable parameters of the go-mysql-api chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.name` | Application name | `go-mysql-api` |
| `app.port` | Application port | `8088` |
| `app.healthCheckPath` | Health check endpoint | `/health` |
| `image.repository` | Docker image repository | `""` |
| `image.tag` | Docker image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8088` |
| `ingress.enabled` | Enable ingress | `false` |
| `configMap.enabled` | Enable ConfigMap | `false` |
| `secret.enabled` | Enable Secret | `false` |
| `hpa.enabled` | Enable HPA | `false` |
| `pdb.enabled` | Enable PDB | `false` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `serviceMonitor.enabled` | Enable ServiceMonitor | `false` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `3306` |
| `DB_NAME` | Database name | `mock_user` |
| `DB_USER` | Database user | `db_user` |
| `DB_PASSWORD` | Database password | `""` |
| `APP_PORT` | Application port | `8088` |
| `APP_ENV` | Application environment | `production` |
| `LOG_LEVEL` | Log level | `info` |
| `AWS_REGION` | AWS region | `us-east-1` |

## Advanced Configuration

### ConfigMap and Secret with Checksums

The chart includes SHA checksums for ConfigMap and Secret names to ensure rolling updates when configuration changes:

```yaml
configMap:
  enabled: true
  data:
    custom.conf: |
      [custom]
      setting = value

secret:
  enabled: true
  data:
    api_key: base64_encoded_key
```

### Horizontal Pod Autoscaler

```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Pod Disruption Budget

```yaml
pdb:
  enabled: true
  minAvailable: 1
```

### Network Policy

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8088
```

### ServiceMonitor for Prometheus

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
  scrapeTimeout: 10s
  path: /metrics
  port: 8088
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls
      hosts:
        - api.example.com
```

## Deployment Examples

### Basic Deployment

```bash
helm install go-mysql-api ./chart \
  --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/sandbox-go-mysql-api-api \
  --set image.tag=latest \
  --set env.DB_HOST=your-rds-endpoint.amazonaws.com \
  --set env.DB_PASSWORD=your-secure-password
```

### Production Deployment

```bash
helm install go-mysql-api ./chart \
  --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/prod-go-mysql-api-api \
  --set image.tag=v1.0.0 \
  --set replicaCount=3 \
  --set hpa.enabled=true \
  --set pdb.enabled=true \
  --set configMap.enabled=true \
  --set secret.enabled=true \
  --set ingress.enabled=true \
  --set serviceMonitor.enabled=true \
  --set env.DB_HOST=prod-rds-endpoint.amazonaws.com \
  --set env.DB_PASSWORD=prod-secure-password \
  --set env.APP_ENV=production \
  --set env.LOG_LEVEL=warn
```

### Development Deployment

```bash
helm install go-mysql-api-dev ./chart \
  --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/dev-go-mysql-api-api \
  --set image.tag=dev \
  --set replicaCount=1 \
  --set configMap.enabled=true \
  --set env.DB_HOST=dev-rds-endpoint.amazonaws.com \
  --set env.DB_PASSWORD=dev-password \
  --set env.APP_ENV=development \
  --set env.LOG_LEVEL=debug
```

## Updating the Application

### Rolling Update

```bash
helm upgrade go-mysql-api ./chart \
  --set image.tag=v1.1.0
```

### Configuration Update

```bash
helm upgrade go-mysql-api ./chart \
  --set env.LOG_LEVEL=debug \
  --set configMap.data.custom.conf="[custom]\nsetting = new_value"
```

## Monitoring and Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=go-mysql-api
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=go-mysql-api
```

### Check Service

```bash
kubectl get svc go-mysql-api
```

### Port Forward for Local Access

```bash
kubectl port-forward svc/go-mysql-api 8088:8088
```

### Health Check

```bash
curl http://localhost:8088/health
```

## Uninstalling

```bash
helm uninstall go-mysql-api
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This project is licensed under the MIT License.
