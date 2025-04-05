# Deployment of SQL Server Developer Edition in Oracle Cloud

This document describes how to deploy SQL Server Developer Edition in Oracle Cloud Free Tier using Ansible.

## Prerequisites

- Oracle Cloud account with Free Tier
- Controller VM with access to Oracle Cloud
- Terraform 1.0+
- Ansible 2.9+
- Git

## Step 1: Clone the repository

```bash
git clone https://github.com/janahlin/sql-server-oracle-cloud.git
cd sql-server-oracle-cloud
```

## Step 2: Get Oracle Cloud Information

Use the provided script to gather your OCI information:

```bash
./scripts/get_oci_info.sh
```

The script will output your OCI configuration details that you'll need for the Ansible vault.

## Step 3: Configure Ansible Vault

1. Create a vault password file (not tracked in Git):
   ```bash
   echo "your-secure-vault-password" > ansible/.vault_pass.txt
   chmod 600 ansible/.vault_pass.txt
   ```

2. Create and edit the vault file with your sensitive information:
   ```bash
   cd ansible
   ansible-vault create group_vars/all/vault.yml
   ```

3. Add your sensitive information to the vault (or copy from the output of get_oci_info.sh):
   ```yaml
   # Oracle Cloud credentials
   vault_oci_tenancy_ocid: "ocid1.tenancy.oc1..exampleuniqueID"
   vault_oci_user_ocid: "ocid1.user.oc1..exampleuniqueID"
   vault_oci_fingerprint: "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
   vault_oci_private_key_path: "~/.oci/oci_api_key.pem"

   # Windows VM credentials
   vault_windows_admin_password: "YourSecurePassword123!"
   vault_ssh_private_key_path: "~/.ssh/id_rsa"
   vault_ssh_public_key: "ssh-rsa AAAA...yourpublickey"
   ```

## Step 4: Configure non-sensitive variables

1. Edit the non-sensitive variables in `ansible/group_vars/all/vars.yml`:
   ```yaml
   # Oracle Cloud configuration
   oci_region: "eu-amsterdam-1"
   oci_compartment_id: "{{ vault_oci_tenancy_ocid }}"  # Using tenancy as compartment for simplicity

   # VM configuration
   vm_shape: "VM.Standard.A1.Flex"
   vm_ocpus: 2
   vm_memory_in_gbs: 8
   availability_domain: "AD-1"
   windows_image_id: "ocid1.image.oc1..exampleimageID"  # Windows Server 2022 image OCID
   ```

## Step 5: Deploy the entire infrastructure

The `ansible.cfg` file is already configured to use your vault password file, so you can simply run:

```bash
cd ansible
ansible-playbook site.yml
```

This playbook will:
1. Create the Terraform configuration from Ansible variables
2. Apply the Terraform configuration to create the infrastructure
3. Update the Ansible inventory with the Windows VM IP
4. Configure the Windows VM
5. Install and configure SQL Server

## Step 6: Verify the installation

1. Connect to SQL Server via SQL Server Management Studio (SSMS) or Azure Data Studio
2. Verify that SQL Server is correctly configured
3. Check the performance settings

## Troubleshooting

If you encounter problems during deployment, check the following:

1. Oracle Cloud authentication is correctly configured in the vault
2. The Windows image ID is valid and accessible
3. Ansible can connect to the Windows VM
4. WinRM is correctly configured on Windows Server
5. Network connection to SQL Server is working

For more help, see [Troubleshooting.md](troubleshooting.md).
