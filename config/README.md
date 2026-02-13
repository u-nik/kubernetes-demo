# Configuration Directory

This directory contains the central repository configuration for ArgoCD applications.

## ⚠️ Important Security Notice

**Never commit `values.yaml` to git!**  
This file contains sensitive credentials and is already excluded in `.gitignore`.

## Files

### `values.yaml.example`
- ✅ **Committed to repository**
- Template file showing the required structure
- Safe to share and version control

### `values.yaml`
- ❌ **NOT committed to repository**
- Contains your actual Bitbucket credentials
- Created by copying `values.yaml.example` and filling in real values

## Setup Instructions

1. Copy the example file:
   ```bash
   cp values.yaml.example values.yaml
   ```

2. Edit `values.yaml` with your Bitbucket credentials:
   ```bash
   nano values.yaml  # or use your editor
   ```

3. Fill in your Bitbucket username and App Password

4. Deploy the credentials:
   ```bash
   kubectl apply -f ../kubernetes/apps/argocd-git-credentials.yaml
   ```

For detailed setup instructions, see [REPOSITORY-SETUP.md](../REPOSITORY-SETUP.md)

## How It Works

The `values.yaml` file is used by the ArgoCD application `argocd-git-credentials` to create a Kubernetes secret that allows ArgoCD to authenticate with the Bitbucket repository.

The values are injected into the Helm chart at:
```
kubernetes/manifests/argocd-git-credentials/
```

## Getting Bitbucket App Password

1. Go to https://bitbucket.org
2. Profile → Personal settings → App passwords
3. Create app password with "Repositories: Read" permission
4. Copy the generated password to `values.yaml`

See [REPOSITORY-SETUP.md](../REPOSITORY-SETUP.md) for complete guide.
