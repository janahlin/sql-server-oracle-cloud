#!/bin/bash
# Fix missing OCI variables in Ansible

echo "Fixing Ansible variable loading issue..."

# Create proper vars.yml file with correct references
cat > ansible/group_vars/all/vars.yml << 'EOF'
---
# Non-sensitive variables
deployment_environment: "dev"

# Oracle Cloud variables
oci_tenancy_ocid: "{{ vault_oci_tenancy_ocid }}"
oci_user_ocid: "{{ vault_oci_user_ocid }}"
oci_fingerprint: "{{ vault_oci_fingerprint }}"
oci_private_key_path: "{{ vault_oci_private_key_path }}"
oci_region: "eu-stockholm-1"
oci_compartment_id: "{{ vault_oci_tenancy_ocid }}"  # Using tenancy as compartment

# VM configuration
availability_domain: "GiQi:EU-STOCKHOLM-1-AD-1"
windows_image_id: "ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
ssh_public_key: "{{ vault_ssh_public_key }}"

# Network configuration
vcn_name: "sqlserver-vcn"
vcn_cidr: "10.0.0.0/16"

# SQL Server configuration
sql_server_data_dir: "C:\\SQLData"
sql_server_log_dir: "C:\\SQLLogs"
sql_server_backup_dir: "C:\\SQLBackup"
EOF

chmod 600 ansible/group_vars/all/vars.yml

# Check if vault.yml exists and has the required variables
if [ ! -f "ansible/group_vars/all/vault.yml" ]; then
  echo "Error: vault.yml is missing. Creating a template..."

  # Create a template vault file
  cat > ansible/group_vars/all/vault.yml.template << 'EOF'
---
# Oracle Cloud credentials - REPLACE THESE WITH YOUR REAL VALUES
vault_oci_tenancy_ocid: "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxx"
vault_oci_user_ocid: "ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxx"
vault_oci_fingerprint: "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
vault_oci_private_key_path: "~/.oci/oci_api_key.pem"

# Windows VM credentials
vault_windows_admin_password: "YourSecurePassword123!"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "ssh-rsa AAAAB...your_complete_ssh_key_here"
EOF

  echo "You need to edit the vault.yml template with your credentials:"
  echo "cd ansible"
  echo "ansible-vault create group_vars/all/vault.yml --vault-password-file=.vault_pass.txt"
  echo "# Copy content from group_vars/all/vault.yml.template and replace values"
else
  echo "vault.yml exists, checking if we need to update credentials..."

  # Get OCI CLI config if available
  if command -v oci &> /dev/null && [ -f ~/.oci/config ]; then
    echo "OCI CLI config found, getting values..."

    # Get values from OCI config
    CONFIG_SECTION=$(sed -n '/\[DEFAULT\]/,/\[/p' ~/.oci/config | sed '/\[.*\]/d;/^$/d')
    TENANCY=$(echo "$CONFIG_SECTION" | grep "^tenancy=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    USER=$(echo "$CONFIG_SECTION" | grep "^user=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    FINGERPRINT=$(echo "$CONFIG_SECTION" | grep "^fingerprint=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    KEY_FILE=$(echo "$CONFIG_SECTION" | grep "^key_file=" | head -1 | cut -d'=' -f2 | tr -d ' ')

    # Create temporary vault content with actual values
    TMP_VAULT=$(mktemp)
    cat > "$TMP_VAULT" << EOF
---
# Oracle Cloud credentials
vault_oci_tenancy_ocid: "$TENANCY"
vault_oci_user_ocid: "$USER"
vault_oci_fingerprint: "$FINGERPRINT"
vault_oci_private_key_path: "$KEY_FILE"

# Windows VM credentials
vault_windows_admin_password: "YourSecurePassword123!"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'ssh-rsa YOUR_SSH_KEY')"
EOF

    # Create new vault.yml
    cd ansible
    ansible-vault encrypt "$TMP_VAULT" --output="group_vars/all/vault.yml" --vault-password-file=.vault_pass.txt
    cd ..

    # Clean up
    rm "$TMP_VAULT"
    echo "Updated vault.yml with OCI config values"
  else
    echo "OCI CLI not configured. Please edit vault.yml manually:"
    echo "cd ansible"
    echo "ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass.txt"
  fi
fi

echo "Variable configuration complete. Try running the deployment again."
