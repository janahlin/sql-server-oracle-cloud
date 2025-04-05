#!/usr/bin/env python3
"""
Script to convert Ansible vault variables to Terraform tfvars.
This script assumes that the Ansible vault has been decrypted beforehand.
"""

import os
import sys
import yaml
import re

# Define paths
ANSIBLE_VAULT_PATH = os.path.join('ansible', 'group_vars', 'all', 'vault.yml')
TERRAFORM_VARS_PATH = os.path.join('terraform', 'environments', 'dev', 'terraform.tfvars')
TERRAFORM_VARS_TEMPLATE_PATH = os.path.join('terraform', 'environments', 'dev', 'terraform.tfvars.template')

def load_ansible_vars(vault_path):
    """Load decrypted Ansible vault variables"""
    with open(vault_path, 'r') as f:
        vault_data = yaml.safe_load(f)
    return vault_data

def generate_tfvars(vault_data, template_path, output_path):
    """Generate tfvars file from Ansible vault data"""
    # Read template file
    with open(template_path, 'r') as f:
        template = f.read()

    # Replace variables in template
    content = template

    # Azure variables
    content = content.replace("{{ vault_azure_subscription_id }}", vault_data.get('vault_azure_subscription_id', ''))
    content = content.replace("{{ vault_azure_tenant_id }}", vault_data.get('vault_azure_tenant_id', ''))
    content = content.replace("{{ vault_azure_client_id }}", vault_data.get('vault_azure_client_id', ''))
    content = content.replace("{{ vault_azure_client_secret }}", vault_data.get('vault_azure_client_secret', ''))
    content = content.replace("{{ vault_windows_admin_password }}", vault_data.get('vault_windows_admin_password', ''))

    # SSH key
    content = content.replace("{{ vault_ssh_public_key }}", vault_data.get('vault_ssh_public_key', ''))

    # Write output file
    with open(output_path, 'w') as f:
        f.write(content)

    print(f"Generated {output_path} from Ansible vault variables")

def main():
    # Check if template exists
    if not os.path.exists(TERRAFORM_VARS_TEMPLATE_PATH):
        # If not, copy the existing tfvars as a template
        if os.path.exists(TERRAFORM_VARS_PATH):
            with open(TERRAFORM_VARS_PATH, 'r') as src:
                content = src.read()

            with open(TERRAFORM_VARS_TEMPLATE_PATH, 'w') as dest:
                dest.write(content)
            print(f"Created template file at {TERRAFORM_VARS_TEMPLATE_PATH}")
        else:
            print(f"Error: Neither {TERRAFORM_VARS_TEMPLATE_PATH} nor {TERRAFORM_VARS_PATH} exists")
            sys.exit(1)

    # Load Ansible vault variables
    vault_data = load_ansible_vars(ANSIBLE_VAULT_PATH)

    # Generate tfvars file
    generate_tfvars(vault_data, TERRAFORM_VARS_TEMPLATE_PATH, TERRAFORM_VARS_PATH)

if __name__ == "__main__":
    main()
