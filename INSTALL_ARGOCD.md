# Argo CD Installation

Install Argo CD in the `argocd` namespace using Helm directly:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values kubernetes/apps/argocd/values.yaml
```

Alternatively, once Argo CD is running, apply the Application manifest to let Argo CD manage itself:

```bash
kubectl apply -f kubernetes/argocd-apps/argocd.yaml
```

Then remove the Helm install and let Argo CD take over permanent management.
