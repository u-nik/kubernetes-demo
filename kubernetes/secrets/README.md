# Secrets Directory

**⚠️ WARNING: Do not commit actual secrets to this directory!**

This directory is for managing Kubernetes secrets locally during development.

## Usage

For production environments, use **HashiCorp Vault** with External Secrets Operator instead of managing secrets manually.

See [VAULT-SETUP.md](../../VAULT-SETUP.md) for Vault integration guide.

## Applying Secrets

If you need to manually create secrets (not recommended for production):

```bash
kubectl create secret generic my-secret --from-literal=key=value
```

## Security Best Practices

- ✅ Use Vault for all environments
- ✅ Never commit secrets to Git
- ✅ Use External Secrets Operator for automatic syncing
- ✅ Rotate credentials regularly
- ❌ Don't store secrets in plain text files
