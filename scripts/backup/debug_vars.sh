#!/bin/bash
# Debug script to check missing variables
set -e

cd ansible

# Create a debug playbook
cat > debug_variables.yml << 'EOF'
---
- name: Debug Variables
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    required_vars:
      - oci_tenancy_ocid
      - oci_user_ocid
      - oci_fingerprint
      - oci_private_key_path
      - oci_region
      - oci_compartment_id
      - availability_domain
      - windows_image_id
      - ssh_public_key

  tasks:
    - name: Display variable status
      ansible.builtin.debug:
        msg: "{{ item }}: {{ lookup('vars', item, default='UNDEFINED') }}"
      loop: "{{ required_vars }}"

    - name: Check for undefined variables
      ansible.builtin.fail:
        msg: "Required variable '{{ item }}' is undefined"
      when: lookup('vars', item, default='UNDEFINED') == 'UNDEFINED'
      loop: "{{ required_vars }}"
EOF

echo "Running variable check playbook..."
ansible-playbook debug_variables.yml --vault-password-file=.vault_pass.txt

# Clean up
rm debug_variables.yml
