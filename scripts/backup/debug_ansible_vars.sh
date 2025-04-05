#!/bin/bash
# Debug and fix Ansible variable loading issues

echo "==== Debugging Ansible Variables ===="

# Create a debug playbook
cat > ansible/debug_vars.yml << 'EOF'
---
- name: Debug Variables
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Display loaded variables
      ansible.builtin.debug:
        msg:
          - "oci_tenancy_ocid (exists: {{ oci_tenancy_ocid is defined }})"
          - "vault_oci_tenancy_ocid (exists: {{ vault_oci_tenancy_ocid is defined }})"

    - name: Show inventory sources
      ansible.builtin.debug:
        var: ansible_inventory_sources

    - name: Show group_vars directory contents
      ansible.builtin.command: ls -la "{{ playbook_dir }}/group_vars/all"
      register: ls_output
      changed_when: false

    - name: Display group_vars contents
      ansible.builtin.debug:
        var: ls_output.stdout_lines
EOF

echo "Running debug playbook..."
cd ansible
ansible-playbook debug_vars.yml

# Fix issue by directly setting variables in group_vars
echo "Creating direct variables file..."
cat > ansible/group_vars/all/direct_vars.yml << EOF
---
# Direct OCI variables - sourced from config
oci_tenancy_ocid: "$(grep "^tenancy=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"
oci_user_ocid: "$(grep "^user=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"
oci_fingerprint: "$(grep "^fingerprint=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"
oci_private_key_path: "$(grep "^key_file=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"
oci_region: "$(grep "^region=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"
oci_compartment_id: "$(grep "^tenancy=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')"

# VM configuration
availability_domain: "GiQi:EU-STOCKHOLM-1-AD-1"
windows_image_id: "ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
ssh_public_key: "$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'YOUR_SSH_KEY')"

# Other variables
deployment_environment: "dev"
vcn_name: "sqlserver-vcn"
vcn_cidr: "10.0.0.0/16"
sql_server_data_dir: "C:\\SQLData"
sql_server_log_dir: "C:\\SQLLogs"
sql_server_backup_dir: "C:\\SQLBackup"
EOF

echo "Created direct_vars.yml with OCI values from config."
echo
echo "Variables should now be available. Try running the deployment again:"
echo "cd .."
echo "./scripts/deploy.sh"

# Clean up
rm ansible/debug_vars.yml
