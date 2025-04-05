#!/bin/bash

echo "Gathering OCI information..."

# Suppress the API key warning
export SUPPRESS_LABEL_WARNING=True

# Get config values directly from the config file
CONFIG_FILE=~/.oci/config
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading from OCI config file: $CONFIG_FILE"

    # Get values only from the DEFAULT profile section
    DEFAULT_SECTION=$(sed -n '/\[DEFAULT\]/,/\[/p' $CONFIG_FILE | sed '/\[.*\]/d;/^$/d')

    # Get tenancy (only first match)
    TENANCY_OCID=$(echo "$DEFAULT_SECTION" | grep "^tenancy=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Tenancy OCID: $TENANCY_OCID"

    # Get user (only first match)
    USER_OCID=$(echo "$DEFAULT_SECTION" | grep "^user=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "User OCID: $USER_OCID"

    # Get fingerprint (only first match)
    FINGERPRINT=$(echo "$DEFAULT_SECTION" | grep "^fingerprint=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Fingerprint: $FINGERPRINT"

    # Get region (only first match)
    REGION=$(echo "$DEFAULT_SECTION" | grep "^region=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Region: $REGION"

    # Get private key path (only first match)
    PRIVATE_KEY_PATH=$(echo "$DEFAULT_SECTION" | grep "^key_file=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    echo "Private Key Path: $PRIVATE_KEY_PATH"
else
    echo "Error: OCI config file not found at $CONFIG_FILE"
    echo "Please run 'oci setup config' to create it"
    exit 1
fi

# List compartments (using tenancy OCID from config)
echo -e "\nAvailable Compartments:"
oci iam compartment list --compartment-id "$TENANCY_OCID" --all 2>/dev/null

# List available images for Windows (try different query formats)
echo -e "\nAvailable Windows Server Images:"
oci compute image list --compartment-id "$TENANCY_OCID" --all 2>/dev/null | grep -i windows

# List Availability Domains
echo -e "\nAvailable Availability Domains:"
oci iam availability-domain list --compartment-id "$TENANCY_OCID" 2>/dev/null

# Output information for Ansible vault
echo -e "\n--- Copy the following to your ansible/group_vars/all/vault.yml ---"
echo "vault_oci_tenancy_ocid: \"$TENANCY_OCID\""
echo "vault_oci_user_ocid: \"$USER_OCID\""
echo "vault_oci_fingerprint: \"$FINGERPRINT\""
echo "vault_oci_private_key_path: \"$PRIVATE_KEY_PATH\""
echo "vault_windows_admin_password: \"YourSecurePassword123!\"  # Change this!"
echo "vault_ssh_private_key_path: \"~/.ssh/id_rsa\"  # Change if needed"
echo "vault_ssh_public_key: \"$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'YOUR_SSH_PUBLIC_KEY')\"  # Change if needed"
