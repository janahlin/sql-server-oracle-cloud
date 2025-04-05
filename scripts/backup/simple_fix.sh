#!/bin/bash
# Fix permissions and format issues

echo "Fixing file permissions..."
chmod 600 ansible/.vault_pass.txt
chmod 600 ansible/group_vars/all/vault.yml
chmod 600 ansible/group_vars/all/vars.yml

echo "Updating availability_domain format in vars.yml..."
# Replace the AD-1 format with the full name format
sed -i 's/availability_domain: "AD-1"/availability_domain: "GiQi:EU-STOCKHOLM-1-AD-1"/' ansible/group_vars/all/vars.yml

# Fix the ssh key by removing spaces
echo "Checking SSH key format..."
SSH_KEY=$(grep -oP 'vault_ssh_public_key: "\K[^"]+' ansible/group_vars/all/vault.yml)
if [[ $SSH_KEY == *" "* ]]; then
  echo "Warning: SSH key contains spaces which may cause issues"
  echo "Please edit your vault.yml manually to fix this:"
  echo "cd ansible && ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass.txt"
fi

# Check for example OCIDs
echo "Checking for placeholder OCIDs..."
if grep -q "ocid1.tenancy.oc1..example" ansible/group_vars/all/vault.yml; then
  echo "Warning: Your vault.yml contains example OCIDs, not real ones"
  echo "Please edit your vault.yml manually to add real OCIDs:"
  echo "cd ansible && ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass.txt"
fi

# Fix the reserved environment variable name
echo "Fixing reserved variable name 'environment'..."
sed -i 's/environment: "dev"/deployment_environment: "dev"/' ansible/group_vars/all/vars.yml

echo "Fixes applied. Please edit your vault.yml if needed and try running the deployment again."
