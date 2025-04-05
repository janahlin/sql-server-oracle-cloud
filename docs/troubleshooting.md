# Troubleshooting Guide

This document provides troubleshooting steps for common issues that may be encountered during the deployment of SQL Server in Oracle Cloud.

## Terraform Issues

### Authentication Problems

**Issue:** Terraform fails with authentication errors.

**Solution:**
1. Verify your Oracle Cloud credentials in `~/.oci/config`
2. Ensure your API private key is correctly formatted and located at `~/.oci/oci_api_key.pem`
3. Confirm that your user has the necessary permissions in Oracle Cloud

### Resource Creation Failures

**Issue:** Terraform fails to create resources.

**Solution:**
1. Check Oracle Cloud service limits for your account
2. Verify that the specified shape is available in your region
3. Review the detailed error messages in the Terraform output

## Ansible Issues

### Connection Problems

**Issue:** Ansible cannot connect to the Windows VM.

**Solution:**
1. Verify that the VM is running
2. Check that the security list allows WinRM traffic (TCP 5985/5986)
3. Ensure that the VM's public IP is correctly specified in the inventory
4. Verify that WinRM is properly configured on the VM

### SQL Server Installation Failures

**Issue:** SQL Server installation fails.

**Solution:**
1. Check that the VM meets the SQL Server system requirements
2. Verify that the installation media is accessible
3. Review the SQL Server installation logs at `C:\Program Files\Microsoft SQL Server\...\Setup Bootstrap\Log\`

## Windows VM Issues

### WinRM Configuration

**Issue:** WinRM is not properly configured.

**Solution:**
1. Connect to the VM using RDP
2. Run the following PowerShell command as Administrator:
   ```powershell
   winrm quickconfig
   ```
3. Verify that the WinRM service is running:
   ```powershell
   Get-Service WinRM
   ```

### Disk Configuration

**Issue:** The additional disk for SQL Server data is not properly configured.

**Solution:**
1. Connect to the VM using RDP
2. Open Disk Management (diskmgmt.msc)
3. Check if the disk is visible but not initialized
4. Initialize the disk and format it with NTFS

## SQL Server Issues

### Remote Connection Problems

**Issue:** Cannot connect to SQL Server remotely.

**Solution:**
1. Verify that SQL Server is running:
   ```powershell
   Get-Service MSSQLSERVER
   ```
2. Check that SQL Server is configured for remote connections:
   ```sql
   EXEC sp_configure 'remote access', 1;
   RECONFIGURE;
   ```
3. Ensure that TCP/IP protocol is enabled in SQL Server Configuration Manager
4. Verify that the Windows Firewall allows SQL Server traffic (TCP 1433)

### Authentication Issues

**Issue:** Authentication fails when connecting to SQL Server.

**Solution:**
1. Verify that SQL Server is configured for Windows Authentication
2. Check that the user has the necessary permissions in SQL Server
3. Verify the SQL Server error logs for specific authentication errors

## Network Issues

### Security List Configuration

**Issue:** Network traffic is blocked.

**Solution:**
1. Verify that the security list allows the necessary traffic:
   - RDP (TCP 3389)
   - WinRM (TCP 5985/5986)
   - SQL Server (TCP 1433)
2. Check that the security list is correctly associated with the subnet

### Connectivity Testing

To test network connectivity:

1. Test RDP connectivity:
   ```bash
   nc -zv <windows-vm-ip> 3389
   ```

2. Test WinRM connectivity:
   ```bash
   nc -zv <windows-vm-ip> 5985
   ```

3. Test SQL Server connectivity:
   ```bash
   nc -zv <windows-vm-ip> 1433
   ```
