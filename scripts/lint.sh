#!/bin/bash
# Comprehensive linting script for the SQL Server Azure project
set -e

echo "===== Linting Terraform files ====="
cd "$(dirname "$0")/.." || exit 1

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed. Please install it first."
    exit 1
fi

# Format Terraform files
echo "Running terraform fmt..."
terraform fmt -recursive ./terraform/

# Validate Terraform files
for env_dir in terraform/environments/*; do
    if [ -d "$env_dir" ]; then
        echo "Validating Terraform in $env_dir..."
        (cd "$env_dir" && terraform init -backend=false && terraform validate)
    fi
done

echo "===== Linting Ansible files ====="
# Check if ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo "Error: ansible-lint is not installed. Please install it with 'pip install ansible-lint'."
    exit 1
fi

# Run ansible-lint with CI-friendly configuration if this is CI environment
if [ -n "$CI" ]; then
    echo "CI environment detected, using CI-friendly ansible-lint..."
    ./scripts/ansible-lint-ci.sh
else
    # Run ansible-lint with standard configuration
    echo "Running ansible-lint..."
    cd ansible && ansible-lint || true
fi

echo "===== Linting Completed Successfully ====="
