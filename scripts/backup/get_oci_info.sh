#!/bin/bash
# Script to retrieve OCI information for Ansible vault

echo "===== Oracle Cloud Information Retrieval ====="

# Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    echo "Error: OCI CLI not found. Please install it first:"
    echo "pip install oci-cli"
    echo "oci setup config"
    exit 1
fi

# Get config values from OCI config file
CONFIG_FILE=~/.oci/config
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading from OCI config file: $CONFIG_FILE"

    # Get values from the DEFAULT profile section
    DEFAULT_SECTION=$(sed -n '/\[DEFAULT\]/,/\[/p' $CONFIG_FILE | sed '/\[.*\]/d;/^$/d')

    # Get tenancy
    TENANCY_OCID=$(echo "$DEFAULT_SECTION" | grep "^tenancy=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Tenancy OCID: $TENANCY_OCID"

    # Get user
    USER_OCID=$(echo "$DEFAULT_SECTION" | grep "^user=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "User OCID: $USER_OCID"

    # Get fingerprint
    FINGERPRINT=$(echo "$DEFAULT_SECTION" | grep "^fingerprint=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Fingerprint: $FINGERPRINT"

    # Get region
    REGION=$(echo "$DEFAULT_SECTION" | grep "^region=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Region: $REGION"

    # Get private key path
    PRIVATE_KEY_PATH=$(echo "$DEFAULT_SECTION" | grep "^key_file=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Private Key Path: $PRIVATE_KEY_PATH"
else
    echo "Error: OCI config file not found at $CONFIG_FILE"
    echo "Please run 'oci setup config' to create it"
    exit 1
fi

# Get SSH public key
SSH_PUBLIC_KEY_FILE=~/.ssh/id_rsa.pub
if [ -f "$SSH_PUBLIC_KEY_FILE" ]; then
    SSH_PUBLIC_KEY=$(cat $SSH_PUBLIC_KEY_FILE)
    echo "SSH Public Key: $SSH_PUBLIC_KEY"
else
    echo "Warning: SSH public key file not found at $SSH_PUBLIC_KEY_FILE"
    echo "You'll need to manually add your SSH public key"
fi

# Test OCI CLI connection
echo -e "\nTesting OCI CLI connection..."
if oci iam compartment get --compartment-id $TENANCY_OCID &> /dev/null; then
    echo "OCI CLI connection successful ✓"
else
    echo "OCI CLI connection failed! Please check your configuration."
fi

echo -e "\n===== Vault.yml Template ====="
cat << EOF
---
# Oracle Cloud credentials
vault_oci_tenancy_ocid: "$TENANCY_OCID"
vault_oci_user_ocid: "$USER_OCID"
vault_oci_fingerprint: "$FINGERPRINT"
vault_oci_private_key_path: "$PRIVATE_KEY_PATH"

# Windows VM credentials
vault_windows_admin_password: "YourSecurePassword123!"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "$SSH_PUBLIC_KEY"
EOF

echo -e "\nCopy this template to your vault.yml file using:"
echo "cd ansible"
echo "ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass.txt"
