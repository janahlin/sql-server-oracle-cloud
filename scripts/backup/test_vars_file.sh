#!/bin/bash
# Test creating terraform.tfvars.json file with variables

# Create the directory
mkdir -p ansible/debug

# Create a debug playbook
cat > ansible/debug/test_vars.yml << 'EOF'
---
- name: Test Variable File Creation
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    terraform_vars_file: "debug/terraform.tfvars.json"

  tasks:
    - name: Display all variables
      ansible.builtin.debug:
        msg:
          - "oci_tenancy_ocid: {{ oci_tenancy_ocid | default('UNDEFINED') }}"
          - "oci_user_ocid: {{ oci_user_ocid | default('UNDEFINED') }}"
          - "oci_fingerprint: {{ oci_fingerprint | default('UNDEFINED') }}"
          - "oci_private_key_path: {{ oci_private_key_path | default('UNDEFINED') }}"
          - "oci_region: {{ oci_region | default('UNDEFINED') }}"
          - "oci_compartment_id: {{ oci_compartment_id | default('UNDEFINED') }}"
          - "availability_domain: {{ availability_domain | default('UNDEFINED') }}"
EOF
