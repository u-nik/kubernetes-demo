#!/bin/sh
NAMESPACE=argocd
RELEASE_NAME=argocd
(
    cd "$(git rev-parse --show-toplevel)" && \
    echo "Adding Traefik Helm repository and installing Traefik..." && \
    helm repo add traefik https://traefik.github.io/charts && \
    helm install traefik traefik/traefik -n kube-system --create-namespace && \
    echo "Installing ArgoCD..." && \
    helm dependency update kubernetes/manifests/argocd && \
    helm install $RELEASE_NAME kubernetes/manifests/argocd \
        --namespace $NAMESPACE \
        --create-namespace && \
    echo "Waiting for ArgoCD to be ready..." && \
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n $NAMESPACE --timeout=300s && \
    echo "Applying ArgoCD App-of-Apps manifest..." && \
    kubectl apply -f kubernetes/apps/root.yaml
)