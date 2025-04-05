#!/bin/bash
# Update vault.yml with Azure credentials

echo "Getting Azure configuration values..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI is not installed. Please install it first."
  exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
  echo "You're not logged in to Azure. Please login first:"
  az login
fi

# Get Azure account information
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Ask for service principal information or create one
echo "Do you want to create a new service principal for this deployment? (y/n)"
read create_sp

if [[ "$create_sp" == "y" ]]; then
  echo "Creating a new service principal..."
  SP_INFO=$(az ad sp create-for-rbac --name "sql-server-sp" --role contributor --scope /subscriptions/$SUBSCRIPTION_ID --query "{clientId:appId,clientSecret:password}" -o json)
  CLIENT_ID=$(echo $SP_INFO | jq -r .clientId)
  CLIENT_SECRET=$(echo $SP_INFO | jq -r .clientSecret)
  echo "New service principal created with client ID: $CLIENT_ID"
else
  echo "Please enter your existing service principal client ID:"
  read CLIENT_ID
  echo "Please enter your existing service principal client secret:"
  read -s CLIENT_SECRET
  echo
fi

# Get SSH public key
SSH_KEY=$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'ssh-rsa YOUR_SSH_KEY')

# Ask for Windows admin password
echo "Enter a secure password for the Windows VM admin (or press Enter to use the default):"
read -s WIN_PASSWORD
WIN_PASSWORD=${WIN_PASSWORD:-"YourSecurePassword123!"}
echo

# Manually decrypt the vault file
if [ -f "ansible/.vault_pass.txt" ]; then
  VAULT_PASS=$(cat ansible/.vault_pass.txt)
  if [ -f "ansible/group_vars/all/vault.yml" ]; then
    # Create a new vault.yml file directly
    echo "Creating new vault.yml file..."
    echo "$VAULT_PASS" > /tmp/vault_pass.txt

    cat > /tmp/vault_content.yml << EOF
---
# Azure credentials
vault_azure_subscription_id: "$SUBSCRIPTION_ID"
vault_azure_tenant_id: "$TENANT_ID"
vault_azure_client_id: "$CLIENT_ID"
vault_azure_client_secret: "$CLIENT_SECRET"

# Common credentials
vault_windows_admin_password: "$WIN_PASSWORD"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "$SSH_KEY"
EOF

    # Encrypt the file using ansible-vault with vault-id
    cd ansible
    ansible-vault encrypt /tmp/vault_content.yml --output=group_vars/all/vault.yml --vault-id=default@.vault_pass.txt

    # Clean up
    rm /tmp/vault_content.yml
    rm /tmp/vault_pass.txt

    echo "Updated vault.yml with Azure configuration values"
  else
    echo "Error: vault.yml does not exist"
  fi
else
  echo "Error: .vault_pass.txt does not exist"
fi

echo "Try running the deployment again with:"
echo "./scripts/deploy.sh"
