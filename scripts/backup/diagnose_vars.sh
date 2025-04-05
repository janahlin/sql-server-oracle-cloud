#!/bin/bash
# Diagnose variable loading issues

cd "$(dirname "$0")/.." || exit 1
ROOT_DIR=$(pwd)

echo "=== Ansible Configuration Diagnostics ==="

# 1. Check file permissions and existence
echo -e "\nChecking critical files..."
for file in ansible/group_vars/all/vars.yml ansible/group_vars/all/vault.yml ansible/.vault_pass.txt; do
  if [ -f "$file" ]; then
    echo "✓ $file exists ($(stat -c "%a" "$file") permissions)"
  else
    echo "✗ $file is MISSING"
  fi
done

# 2. Create a diagnostic playbook
cat > ansible/diagnose.yml << 'EOF'
---
- name: Diagnose Variable Issues
  hosts: localhost
  connection: local
  gather_facts: false
  
  tasks:
    - name: Display all current variables
      ansible.builtin.debug:
        var: hostvars[inventory_hostname]
        verbosity: 1

    - name: Check if vars.yml is loaded
      ansible.builtin.stat:
        path: "{{ playbook_dir }}/group_vars/all/vars.yml"
      register: vars_file

    - name: Display vars.yml status
      ansible.builtin.debug:
        msg: "vars.yml {{ 'exists' if vars_file.stat.exists else 'MISSING' }}"

    - name: Check if vault.yml is loaded
      ansible.builtin.stat:
        path: "{{ playbook_dir }}/group_vars/all/vault.yml"
      register: vault_file

    - name: Display vault.yml status
      ansible.builtin.debug:
        msg: "vault.yml {{ 'exists' if vault_file.stat.exists else 'MISSING' }}"

    - name: List critical variables
      ansible.builtin.debug:
        msg: 
          - "oci_tenancy_ocid: {{ oci_tenancy_ocid | default('UNDEFINED') }}"
          - "oci_user_ocid: {{ oci_user_ocid | default('UNDEFINED') }}"
          - "oci_fingerprint: {{ oci_fingerprint | default('UNDEFINED') }}"
          - "oci_private_key_path: {{ oci_private_key_path | default('UNDEFINED') }}"
          - "oci_region: {{ oci_region | default('UNDEFINED') }}"
          - "oci_compartment_id: {{ oci_compartment_id | default('UNDEFINED') }}"
          - "availability_domain: {{ availability_domain | default('UNDEFINED') }}"
          - "windows_image_id: {{ windows_image_id | default('UNDEFINED') }}"
          - "ssh_public_key: {{ ssh_public_key | default('UNDEFINED') }}"

    - name: Check vault variables 
      ansible.builtin.debug:
        msg:
          - "vault_oci_tenancy_ocid: {{ vault_oci_tenancy_ocid | default('UNDEFINED') }}"
          - "vault_oci_user_ocid: {{ vault_oci_user_ocid | default('UNDEFINED') }}"
          - "vault_oci_fingerprint: {{ vault_oci_fingerprint | default('UNDEFINED') }}"
          - "vault_oci_private_key_path: {{ vault_oci_private_key_path | default('UNDEFINED') }}"
          - "vault_ssh_public_key: {{ vault_ssh_public_key | default('UNDEFINED') }}"
EOF

# 3. Run the diagnostic playbook
echo -e "\nRunning diagnostics..."
cd ansible
ansible-playbook diagnose.yml -v

# 4. Provide debugging commands
echo -e "\n=== Common Solutions ==="
echo "1. Check your vars.yml contents:"
echo "   cat ansible/group_vars/all/vars.yml"
echo
echo "2. Edit your vault.yml:"
echo "   cd ansible && ansible-vault edit group_vars/all/vault.yml --vault-password-file=.vault_pass.txt" 
echo
echo "3. Create template vars.yml if missing:"
cat << 'EOT'
# Create this file as ansible/group_vars/all/vars.yml:
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
EOT

# Clean up
rm ansible/diagnose.yml 