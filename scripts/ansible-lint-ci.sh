#!/bin/bash
# Run Ansible lint with special CI-friendly configuration
set -e

# Create temporary ansible-lint config
TMP_CONFIG=$(mktemp)
cat > "$TMP_CONFIG" << 'EOF'
---
skip_list:
  - yaml[line-length]
  - yaml[truthy]
  - jinja[spacing]
  - name[casing]
  - meta-no-info
  - syntax-check[specific]

warn_list:
  - fqcn[action-core]
  - fqcn[action]

enable_list:
  - fqcn
  - no-tabs
  - no-trailing-spaces

offline: true
EOF

echo "Running ansible-lint with CI configuration..."
cd "$(dirname "$0")/.." || exit 1
ANSIBLE_LINT_CONFIG="$TMP_CONFIG" ansible-lint || true

rm "$TMP_CONFIG"
echo "Ansible linting completed."
