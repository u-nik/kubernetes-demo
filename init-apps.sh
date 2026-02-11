#!/bin/sh
set -x
NAMESPACE=argocd
RELEASE_NAME=argocd
(
    cd "$(git rev-parse --show-toplevel)" && \
    helm dependency update kubernetes/manifests/argocd && \
    helm install $RELEASE_NAME kubernetes/manifests/argocd \
        --namespace $NAMESPACE \
        --create-namespace
)