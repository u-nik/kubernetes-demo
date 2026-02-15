#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ansible-playbook -i "$ROOT_DIR/ansible/inventory.ini" "$ROOT_DIR/ansible/init-cluster.yml" $@
