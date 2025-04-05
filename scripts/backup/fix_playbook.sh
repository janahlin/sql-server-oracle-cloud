#!/bin/bash
# Directly modify the deployment playbook to include hardcoded variables

# Back up the original file
cp ansible/playbooks/deploy_infrastructure.yml ansible/playbooks/deploy_infrastructure.yml.bak

# Get values from OCI config
TENANCY_OCID=$(grep "^tenancy=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
USER_OCID=$(grep "^user=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
FINGERPRINT=$(grep "^fingerprint=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
KEY_FILE=$(grep "^key_file=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
REGION=$(grep "^region=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

# Create a modified playbook with hardcoded values
cat > ansible/playbooks/deploy_infrastructure.yml << EOF
---
- name: Deploy Oracle Cloud Infrastructure
  hosts: localhost
  connection: local
  gather_facts: true

  vars:
    # Hardcoded OCI values from config
    oci_tenancy_ocid: "${TENANCY_OCID}"
    oci_user_ocid: "${USER_OCID}"
    oci_fingerprint: "${FINGERPRINT}"
    oci_private_key_path: "${KEY_FILE}"
    oci_region: "${REGION}"
    oci_compartment_id: "${TENANCY_OCID}"
    availability_domain: "GiQi:EU-STOCKHOLM-1-AD-1"
    windows_image_id: "ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
    ssh_public_key: "${SSH_KEY}"
    
    terraform_dir: "{{ playbook_dir }}/../../terraform/environments/dev"
    terraform_vars_file: "{{ terraform_dir }}/terraform.tfvars.json"

  tasks:
    - name: Create terraform.tfvars.json from Ansible variables
      ansible.builtin.copy:
        dest: "{{ terraform_vars_file }}"
        content: |
          {
            "tenancy_ocid": "{{ oci_tenancy_ocid }}",
            "user_ocid": "{{ oci_user_ocid }}",
            "fingerprint": "{{ oci_fingerprint }}",
            "private_key_path": "{{ oci_private_key_path }}",
            "region": "{{ oci_region }}",
            "compartment_id": "{{ oci_compartment_id }}",
            "availability_domain": "{{ availability_domain }}",
            "windows_image_id": "{{ windows_image_id }}",
            "ssh_public_key": "{{ ssh_public_key }}"
          }
        mode: '0600'

    - name: Initialize Terraform
      ansible.builtin.command: terraform init
      args:
        chdir: "{{ terraform_dir }}"
      changed_when: false

    - name: Run Terraform plan
      ansible.builtin.command: terraform plan -var-file={{ terraform_vars_file | basename }}
      args:
        chdir: "{{ terraform_dir }}"
      register: terraform_plan
      changed_when: false

    - name: Apply Terraform changes
      ansible.builtin.command: terraform apply -auto-approve -var-file={{ terraform_vars_file | basename }}
      args:
        chdir: "{{ terraform_dir }}"
      register: terraform_apply
      changed_when: false

    - name: Get Terraform outputs
      ansible.builtin.command: terraform output -json
      args:
        chdir: "{{ terraform_dir }}"
      register: terraform_output
      changed_when: false

    - name: Parse Terraform outputs
      ansible.builtin.set_fact:
        terraform_outputs: "{{ terraform_output.stdout | from_json }}"

    - name: Set Windows VM IP
      ansible.builtin.set_fact:
        windows_vm_ip: "{{ terraform_outputs.windows_vm_public_ip.value }}"

    - name: Update Ansible inventory with Windows VM IP
      ansible.builtin.template:
        src: "{{ playbook_dir }}/../templates/hosts.j2"
        dest: "{{ playbook_dir }}/../inventory/hosts"
        mode: '0644'
EOF

echo "Modified the deployment playbook with hardcoded values."
echo "Try running the deployment again:"
echo "./scripts/deploy.sh" 