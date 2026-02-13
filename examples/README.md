# ExternalSecret Examples

This directory contains example ExternalSecret manifests showing how to create different types of secrets from Vault.

## Prerequisites

1. Vault SecretStore deployed: `kubectl apply -f kubernetes/apps/vault-secretstore.yaml`
2. Secrets stored in Vault at the specified paths

## Pattern Overview

All examples follow the same pattern:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <descriptive-name>         # Specific to this secret's purpose
  namespace: <target-namespace>
spec:
  refreshInterval: <duration>       # How often to sync
  secretStoreRef:
    name: vault-cluster-secretstore  # REUSABLE - same for all
    kind: ClusterSecretStore
  target:
    name: <kubernetes-secret-name>  # Secret created in K8s
  data:
    - secretKey: <key-in-k8s-secret>
      remoteRef:
        key: <vault-path>            # Where in Vault
        property: <key-in-vault>     # Which field
```

## Examples Included

### 1. PostgreSQL Credentials
**File**: `postgresql-credentials-externalsecret.yaml`

Store in Vault:
```bash
vault kv put secret/database/postgresql \
  username="dbuser" \
  password="dbpass" \
  host="postgresql.default.svc.cluster.local"
```

Creates K8s secret: `postgresql-credentials` with username, password, host

### 2. API Keys
**File**: `api-keys-externalsecret.yaml`

Store in Vault:
```bash
vault kv put secret/api/stripe api_key="sk_live_..."
vault kv put secret/api/sendgrid api_key="SG...."
vault kv put secret/api/slack webhook_url="https://hooks.slack.com/..."
```

Creates K8s secret: `api-keys-secret` with all API keys

### 3. Application Config
**File**: `app-config-externalsecret.yaml`

Store in Vault:
```bash
vault kv put secret/myapp/config \
  db_host="postgres.default.svc" \
  db_port="5432" \
  db_name="myapp" \
  redis_host="redis.default.svc" \
  feature_new_ui="true"
```

Creates K8s secret: `app-config-secret` with templated config file

## Usage

1. **Store secrets in Vault** at the paths specified in the examples
2. **Apply the ExternalSecret**:
   ```bash
   kubectl apply -f postgresql-credentials-externalsecret.yaml
   ```
3. **Verify it synced**:
   ```bash
   kubectl get externalsecret postgresql-credentials
   kubectl get secret postgresql-credentials
   ```

## Important Notes

### ✅ What's Reusable
- **SecretStore/ClusterSecretStore** - Connection to Vault (created once)
- The pattern itself - copy and adapt for new secrets

### 🎯 What's Specific
- **ExternalSecret name** - Should describe the secret's purpose
- **Vault path** - Where the secret lives in Vault
- **Target secret name** - Name of the K8s secret to create
- **Data mappings** - Which Vault keys map to which secret keys

### ClusterSecretStore vs SecretStore

**ClusterSecretStore** (recommended):
- ✅ Can be used by ExternalSecrets in ANY namespace
- ✅ One SecretStore for entire cluster
- Example: `vault-cluster-secretstore`

**SecretStore** (namespace-scoped):
- ⚠️ Can only be used in the same namespace
- Use when you need namespace isolation
- Example: `vault-secretstore` in argocd namespace

## Best Practices

1. **One ExternalSecret per logical secret group**
   - Database credentials → one ExternalSecret
   - API keys → one ExternalSecret
   - Don't mix unrelated secrets

2. **Use descriptive names**
   - ✅ `postgresql-credentials`, `api-keys`, `stripe-config`
   - ❌ `secret1`, `creds`, `keys`

3. **Organize Vault paths logically**
   ```
   secret/
   ├── database/
   │   ├── postgresql
   │   └── mongodb
   ├── api/
   │   ├── stripe
   │   ├── sendgrid
   │   └── slack
   └── argocd/
       └── git-credentials
   ```

4. **Use ClusterSecretStore for shared access**
   - All apps can use the same SecretStore
   - No need to duplicate SecretStore per namespace

5. **Set appropriate refresh intervals**
   - Credentials: 1h or more
   - Frequently changing: 5m - 15m
   - Rarely changing: 24h

## Troubleshooting

Check ExternalSecret status:
```bash
kubectl describe externalsecret <name>
```

View events:
```bash
kubectl get events --sort-by='.lastTimestamp' | grep ExternalSecret
```

Check ESO logs:
```bash
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets --tail=50
```

Force sync:
```bash
kubectl annotate externalsecret <name> \
  force-sync=$(date +%s) --overwrite
```

## More Information

- [External Secrets Operator Docs](https://external-secrets.io/)
- [Vault Provider](https://external-secrets.io/latest/provider/hashicorp-vault/)
- [VAULT-SETUP.md](../VAULT-SETUP.md)
- [VAULT-QUICK-REFERENCE.md](../VAULT-QUICK-REFERENCE.md)
