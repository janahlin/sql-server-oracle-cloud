# Troubleshooting Guide

This document provides solutions to common issues you might encounter when deploying SQL Server on Azure using this repository.

## Azure Authentication Issues

**Symptom**: Terraform fails with authentication errors.

**Solutions**:
1. Verify that your Azure credentials are correct in the `terraform.tfvars` file.
2. Ensure that the Service Principal has Contributor permissions on the subscription.
3. Check if the credentials have expired. Service Principal passwords expire by default.
4. Run `az login` to verify that your CLI can access Azure.

**Example error**:
```
Error: Error building account: Error getting authenticated object ID: Error parsing json result from the Azure CLI: Error waiting for the Azure CLI: exit status 1
```

## Terraform Deployment Failures

**Symptom**: Terraform apply fails during resource creation.

**Solutions**:
1. Check if the requested VM size is available in your selected region.
2. Verify that you have not reached quotas or limits on your Azure subscription.
3. Try using a different region by changing the `location` variable.
4. Run `terraform plan` to identify the specific issue before applying.

**Example error**:
```
Error: compute.VirtualMachinesClient#CreateOrUpdate: Failure sending request: StatusCode=400 -- Original Error: Code="SkuNotAvailable" Message="The requested size for resource '/subscriptions/...' is currently not available in location 'westeurope' zones '' for subscription '...'. Please try another size or deploy to a different location or zones."
```

## Windows VM Connectivity Issues

**Symptom**: Cannot connect to Windows VM via RDP or WinRM.

**Solutions**:
1. Verify that the VM is running in the Azure portal.
2. Check if the Network Security Group allows traffic on ports 3389 (RDP) and 5985/5986 (WinRM).
3. Ensure that the VM's public IP address is correct in your Ansible inventory.
4. Reset the VM's password from the Azure portal if necessary.

**Commands to check**:
```bash
# Check VM status
az vm show -g sql-server-rg -n sqlserver-dev --query "powerState"

# Check NSG rules
az network nsg rule list -g sql-server-rg --nsg-name sql-server-vnet-nsg -o table
```

## Ansible Connection Failures

**Symptom**: Ansible fails to connect to the Windows VM.

**Solutions**:
1. Verify that WinRM is properly configured on the VM.
2. Check that the Ansible inventory file has the correct IP address.
3. Ensure that the username and password are correct.
4. Wait a few minutes after VM creation for services to fully start.

**Example error**:
```
fatal: [sqlserver]: UNREACHABLE! => {"changed": false, "msg": "ssl: HTTPSConnectionPool(host='X.X.X.X', port=5986): Max retries exceeded with url: /wsman (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x7f05d9f97af0>, 'Connection to X.X.X.X timed out. (connect timeout=30)'))", "unreachable": true}
```

## SQL Server Installation Issues

**Symptom**: SQL Server installation fails during Ansible playbook execution.

**Solutions**:
1. Ensure VM has enough resources (minimum 1.4 GB RAM for SQL Server).
2. Check that the Windows VM can access the internet to download SQL Server.
3. Verify that the installation script has proper permissions.
4. Manually connect to the VM and check Windows Event Logs for specific errors.

**Manual SQL Server installation check**:
```powershell
# Check SQL Server service status
Get-Service -Name MSSQLSERVER

# Check SQL Server error log
Get-Content "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\ERRORLOG"
```

## Disk Space Issues

**Symptom**: Deployment fails due to insufficient disk space.

**Solutions**:
1. Check the available disk space on the VM.
2. Increase the disk size in the Terraform configuration.
3. Clean up temporary installation files.

**Commands to check**:
```powershell
# Check disk space on Windows
Get-PSDrive -PSProvider FileSystem
```

## Azure Resource Constraints

**Symptom**: Deployment fails due to resource quotas or constraints.

**Solutions**:
1. Verify that your subscription has enough quota for the requested resources.
2. Consider using a different VM size or region.
3. Request a quota increase from Microsoft if needed.

**Command to check quotas**:
```bash
az vm list-usage --location westeurope -o table
```
