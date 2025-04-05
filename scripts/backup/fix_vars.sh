#!/bin/bash
# Fix variable and permission issues

# Fix permissions
chmod 600 ansible/.vault_pass.txt
chmod 600 ansible/group_vars/all/vault.yml

# Get actual OCIDs
echo "Please enter your actual Oracle Cloud tenancy OCID:"
read actual_tenancy_ocid

echo "Please enter your actual Oracle Cloud user OCID:"
read actual_user_ocid

echo "Please enter your Oracle Cloud fingerprint:"
read actual_fingerprint

echo "Please enter your SSH public key (without spaces):"
read actual_ssh_key

# Edit vars.yml
cat > ansible/group_vars/all/vars.yml << EOF
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

# Create temporary vault content
cat > /tmp/vault_content.yml << EOF
---
# Oracle Cloud credentials
vault_oci_tenancy_ocid: "${actual_tenancy_ocid}"
vault_oci_user_ocid: "${actual_user_ocid}"
vault_oci_fingerprint: "${actual_fingerprint}"
vault_oci_private_key_path: "~/.oci/oci_api_key.pem"

# Windows VM credentials
vault_windows_admin_password: "YourSecurePassword123!"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "${actual_ssh_key}"
EOF

# Encrypt the vault
cd ansible
ansible-vault encrypt /tmp/vault_content.yml --output=group_vars/all/vault.yml --vault-password-file=.vault_pass.txt

echo "Variables fixed! Try running the deployment script again." 