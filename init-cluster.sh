#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "Ansible is not installed. Please install Ansible to run this script."
    exit 1
fi

ansible-playbook -i "$ROOT_DIR/ansible/inventory.ini" "$ROOT_DIR/ansible/init-cluster.yml" $@
