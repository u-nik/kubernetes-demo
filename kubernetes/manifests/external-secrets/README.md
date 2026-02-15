# External Secrets Operator with Vault

This guide walks you through setting up External Secrets Operator (ESO) with HashiCorp Vault for managing secrets in your Kubernetes cluster.

## 📋 Prerequisites

1. Kubernetes cluster (Docker Desktop, Minikube, or production cluster)
2. HashiCorp Vault running (localhost:8200 for Docker Desktop)
3. kubectl access to your Kubernetes cluster
4. ArgoCD running in your cluster (optional but recommended)

## 🚀 Quick Setup

For a complete automated setup, see [VAULT-SETUP.md](../../../VAULT-SETUP.md).

### Quick Start Scripts

```bash
# Initialize Vault and store credentials
./init-vault.ps1  # Windows PowerShell
./init-cluster.sh # Linux/Mac/WSL

# Deploy to Kubernetes
./deploy-vault-integration.ps1  # Windows PowerShell
# (included in init-cluster.sh for Linux/Mac/WSL)
```

## 📊 Architecture

```
┌─────────────────────┐
│  HashiCorp Vault    │
│  localhost:8200     │
│  (or in-cluster)    │
└──────────┬──────────┘
           │
           │ API Connection (host.docker.internal for Docker Desktop)
           │
┌──────────▼──────────┐
│ External Secrets    │
│    Operator (ESO)   │
└──────────┬──────────┘
           │
           │ Syncs Secrets (every 1h)
           │
┌──────────▼──────────┐
│  Kubernetes Secret  │
│ (auto-synced from   │
│      Vault)         │
└──────────┬──────────┘
           │
           │ Used by
           │
┌──────────▼──────────┐
│   Your Applications │
│   (Pods, ArgoCD)    │
└─────────────────────┘
```

## 🔍 Troubleshooting

### ExternalSecret not syncing

Check the ExternalSecret status:

```bash
kubectl describe externalsecret argocd-git-credentials -n argocd
```

Look for error messages in the status conditions. Common issues:

- Vault path not found
- Invalid token
- Network connectivity

Force a sync:

```bash
kubectl annotate externalsecret argocd-git-credentials -n argocd \
  force-sync=$(date +%s) --overwrite
```

### SecretStore not ready

Check SecretStore status:

```bash
kubectl describe secretstore vault-secretstore -n argocd
```

Verify Vault connectivity:

```bash
# Test from a pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:8200/v1/sys/health
```

Check External Secrets Operator logs:

```bash
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets --tail=50
```

### Vault Connection Issues

For Docker Desktop, ensure you're using `host.docker.internal:8200` in the SecretStore configuration.

Verify the Vault token secret exists:

```bash
kubectl get secret vault-token -n argocd -o yaml
```

## 📚 Additional Examples

### Example: Database Credentials

Store in Vault:

```bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

vault kv put secret/database/postgresql \
  username="dbuser" \
  password="dbpass" \
  host="postgresql.default.svc.cluster.local"
```

Create ExternalSecret:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
    name: postgresql-credentials
    namespace: default
spec:
    refreshInterval: 1h
    secretStoreRef:
        name: vault-cluster-secretstore
        kind: ClusterSecretStore
    target:
        name: postgresql-credentials
    data:
        - secretKey: username
          remoteRef:
              key: database/postgresql
              property: username
        - secretKey: password
          remoteRef:
              key: database/postgresql
              property: password
        - secretKey: host
          remoteRef:
              key: database/postgresql
              property: host
```

Apply and verify:

```bash
kubectl apply -f postgresql-externalsecret.yaml
kubectl get externalsecret postgresql-credentials -n default
kubectl get secret postgresql-credentials -n default
```

### Example: TLS Certificates

Store in Vault:

```bash
vault kv put secret/tls/example-com \
  tls.crt="$(cat cert.pem)" \
  tls.key="$(cat key.pem)"
```

Create ExternalSecret:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
    name: tls-certificate
    namespace: default
spec:
    refreshInterval: 24h
    secretStoreRef:
        name: vault-cluster-secretstore
        kind: ClusterSecretStore
    target:
        name: tls-secret
        template:
            type: kubernetes.io/tls
    data:
        - secretKey: tls.crt
          remoteRef:
              key: tls/example-com
              property: tls.crt
        - secretKey: tls.key
          remoteRef:
              key: tls/example-com
              property: tls.key
```

### Example: API Keys with Templating

Store in Vault:

```bash
vault kv put secret/api/service-a \
  api_key="abc123" \
  api_secret="xyz789"
```

Create ExternalSecret with template:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
    name: api-config
    namespace: default
spec:
    refreshInterval: 1h
    secretStoreRef:
        name: vault-cluster-secretstore
        kind: ClusterSecretStore
    target:
        name: api-config-secret
        template:
            data:
                # Template to create a config file
                config.yaml: |
                    api:
                      key: {{ .api_key }}
                      secret: {{ .api_secret }}
                      endpoint: https://api.service-a.com
    data:
        - secretKey: api_key
          remoteRef:
              key: api/service-a
              property: api_key
        - secretKey: api_secret
          remoteRef:
              key: api/service-a
              property: api_secret
```

## 🔐 Security Best Practices

1. ✅ Use token-based authentication for dev
2. ✅ Use Kubernetes auth method for production
3. ✅ Restrict Vault policies to minimum required access
4. ✅ Regularly rotate credentials in Vault
5. ✅ Use RBAC to limit access to ExternalSecrets
6. ✅ Monitor ESO logs for unauthorized access attempts
7. ✅ Use different Vault namespaces for different environments
8. ✅ Enable Vault audit logging

## 🔗 Useful Links

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [Vault Provider Documentation](https://external-secrets.io/latest/provider/hashicorp-vault/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [ArgoCD Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [VAULT-SETUP.md](../../../VAULT-SETUP.md) - Complete setup guide
- [VAULT-QUICK-REFERENCE.md](../../../VAULT-QUICK-REFERENCE.md) - Daily commands

## 📝 Notes

- The `refreshInterval` controls how often secrets are synced from Vault (default: 1h)
- Use `ClusterSecretStore` for cluster-wide secret management
- Use `SecretStore` for namespace-specific secrets
- ExternalSecrets support templating for complex secret transformations
- For Docker Desktop: Vault at `host.docker.internal:8200` allows containers to access host
- For production: Deploy Vault inside Kubernetes with HA configuration
- Vault KV v2 paths: API adds `/data/` automatically (secret/data/path)
