#!/bin/bash
# Directly update vault.yml with OCI values

echo "Getting OCI configuration values..."

# Get values from OCI config
if [ -f ~/.oci/config ]; then
  CONFIG_SECTION=$(sed -n '/\[DEFAULT\]/,/\[/p' ~/.oci/config | sed '/\[.*\]/d;/^$/d')
  TENANCY=$(echo "$CONFIG_SECTION" | grep "^tenancy=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  USER=$(echo "$CONFIG_SECTION" | grep "^user=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  FINGERPRINT=$(echo "$CONFIG_SECTION" | grep "^fingerprint=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  KEY_FILE=$(echo "$CONFIG_SECTION" | grep "^key_file=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  SSH_KEY=$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'ssh-rsa YOUR_SSH_KEY')
  
  # Manually decrypt the vault file
  if [ -f "ansible/.vault_pass.txt" ]; then
    VAULT_PASS=$(cat ansible/.vault_pass.txt)
    if [ -f "ansible/group_vars/all/vault.yml" ]; then
      # Create a new vault.yml file directly
      echo "Creating new vault.yml file..."
      echo "$VAULT_PASS" > /tmp/vault_pass.txt
      
      cat > /tmp/vault_content.yml << EOF
---
# Oracle Cloud credentials
vault_oci_tenancy_ocid: "$TENANCY"
vault_oci_user_ocid: "$USER"
vault_oci_fingerprint: "$FINGERPRINT"
vault_oci_private_key_path: "$KEY_FILE"

# Windows VM credentials
vault_windows_admin_password: "YourSecurePassword123!"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "$SSH_KEY"
EOF
      
      # Encrypt the file using ansible-vault with vault-id
      cd ansible
      ansible-vault encrypt /tmp/vault_content.yml --output=group_vars/all/vault.yml --vault-id=default@.vault_pass.txt
      
      # Clean up
      rm /tmp/vault_content.yml
      rm /tmp/vault_pass.txt
      
      echo "Updated vault.yml with OCI configuration values"
    else
      echo "Error: vault.yml does not exist"
    fi
  else
    echo "Error: .vault_pass.txt does not exist"
  fi
else
  echo "Error: OCI configuration file not found"
fi

echo "Try running the deployment again with:"
echo "./scripts/deploy.sh" 