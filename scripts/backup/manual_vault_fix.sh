#!/bin/bash
# Guide to manually recreate vault.yml

echo "========= OCI Configuration Values ========="
if [ -f ~/.oci/config ]; then
  CONFIG_SECTION=$(sed -n '/\[DEFAULT\]/,/\[/p' ~/.oci/config | sed '/\[.*\]/d;/^$/d')
  TENANCY=$(echo "$CONFIG_SECTION" | grep "^tenancy=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  USER=$(echo "$CONFIG_SECTION" | grep "^user=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  FINGERPRINT=$(echo "$CONFIG_SECTION" | grep "^fingerprint=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  KEY_FILE=$(echo "$CONFIG_SECTION" | grep "^key_file=" | head -1 | cut -d'=' -f2 | tr -d ' ')
  SSH_KEY=$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'YOUR_SSH_KEY')
  
  echo "Tenancy OCID: $TENANCY"
  echo "User OCID: $USER"
  echo "Fingerprint: $FINGERPRINT"
  echo "Key File: $KEY_FILE"
  echo "SSH Key: $SSH_KEY"
  
  echo "========= Manual Steps ========="
  echo "1. Create a new vault.yml file with:"
  echo "   cd ansible"
  echo "   ansible-vault create group_vars/all/vault.yml"
  echo
  echo "2. When the editor opens, paste these contents:"
  echo "---"
  echo "# Oracle Cloud credentials"
  echo "vault_oci_tenancy_ocid: \"$TENANCY\""
  echo "vault_oci_user_ocid: \"$USER\""
  echo "vault_oci_fingerprint: \"$FINGERPRINT\""
  echo "vault_oci_private_key_path: \"$KEY_FILE\""
  echo
  echo "# Windows VM credentials"
  echo "vault_windows_admin_password: \"YourSecurePassword123!\""
  echo "vault_ssh_private_key_path: \"~/.ssh/id_rsa\""
  echo "vault_ssh_public_key: \"$SSH_KEY\""
  echo
  echo "3. Save the file and exit the editor"
  echo
  echo "4. Run the deployment script again:"
  echo "   ./scripts/deploy.sh"
else
  echo "Error: OCI configuration file not found at ~/.oci/config"
  echo "Please run 'oci setup config' to configure the CLI"
fi 