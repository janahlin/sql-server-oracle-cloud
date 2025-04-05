#!/bin/bash

# Create a modified deployment playbook
cat > ansible/playbooks/deploy_infrastructure.yml << 'ENDOFFILE'
---
- name: Deploy Oracle Cloud Infrastructure
  hosts: localhost
  connection: local
  gather_facts: true

  tasks:
    - name: Initialize Terraform
      ansible.builtin.command: terraform init
      args:
        chdir: "{{ playbook_dir }}/../../terraform/environments/dev"
      changed_when: false

    - name: Run Terraform plan with command line variables
      ansible.builtin.command: >
        terraform plan
        -var="tenancy_ocid=ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va"
        -var="user_ocid=ocid1.user.oc1..aaaaaaaahkxj6jzddyrmwb5ursmz76sesxlcn7htop2nfv3fb66jjzehftza"
        -var="fingerprint=09:fd:0f:58:f5:5e:7f:1c:98:d7:a6:19:76:48:4e:8c"
        -var="private_key_path=~/.oci/oci_api_key.pem"
        -var="region=eu-stockholm-1"
        -var="compartment_id=ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va"
        -var="availability_domain=GiQi:EU-STOCKHOLM-1-AD-1"
        -var="windows_image_id=ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
        -var="shape=VM.Standard2.1"
      args:
        chdir: "{{ playbook_dir }}/../../terraform/environments/dev"
      register: terraform_plan
      changed_when: false

    - name: Apply Terraform changes with command line variables
      ansible.builtin.command: >
        terraform apply -auto-approve
        -var="tenancy_ocid=ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va"
        -var="user_ocid=ocid1.user.oc1..aaaaaaaahkxj6jzddyrmwb5ursmz76sesxlcn7htop2nfv3fb66jjzehftza"
        -var="fingerprint=09:fd:0f:58:f5:5e:7f:1c:98:d7:a6:19:76:48:4e:8c"
        -var="private_key_path=~/.oci/oci_api_key.pem"
        -var="region=eu-stockholm-1"
        -var="compartment_id=ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va"
        -var="availability_domain=GiQi:EU-STOCKHOLM-1-AD-1"
        -var="windows_image_id=ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
        -var="shape=VM.Standard2.1"
      args:
        chdir: "{{ playbook_dir }}/../../terraform/environments/dev"
      register: terraform_apply
      changed_when: false
      ignore_errors: yes

    - name: Get Terraform outputs
      ansible.builtin.command: terraform output -json
      args:
        chdir: "{{ playbook_dir }}/../../terraform/environments/dev"
      register: terraform_output
      changed_when: false
      ignore_errors: yes

    - name: Parse Terraform outputs
      ansible.builtin.set_fact:
        terraform_outputs: "{{ terraform_output.stdout | from_json if terraform_output.rc == 0 else {} }}"
      ignore_errors: yes

    - name: Set Windows VM IP
      ansible.builtin.set_fact:
        windows_vm_ip: "{{ terraform_outputs.windows_vm_public_ip.value if terraform_outputs.windows_vm_public_ip is defined else 'unknown' }}"
      ignore_errors: yes

    - name: Update Ansible inventory with Windows VM IP
      ansible.builtin.template:
        src: "{{ playbook_dir }}/../templates/hosts.j2"
        dest: "{{ playbook_dir }}/../inventory/hosts"
        mode: '0644'
      ignore_errors: yes
ENDOFFILE

# Create a template for the hosts file
mkdir -p ansible/templates
cat > ansible/templates/hosts.j2 << 'ENDOFFILE'
[windows]
sqlserver ansible_host={{ windows_vm_ip }}

[windows:vars]
ansible_user=Administrator
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_winrm_transport=ntlm
ansible_port=5986
ENDOFFILE

# Make sure the inventory directory exists
mkdir -p ansible/inventory

echo "Modified deployment approach to use command-line variables instead of .tfvars file"
echo "Try running the deployment again:"
echo "ansible-playbook ansible/playbooks/deploy_infrastructure.yml"
