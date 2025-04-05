terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to place the VM in"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  description = "Name for the VM"
  type        = string
  default     = "sqlserver-dev"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B1s"
}

# Bootstrap script to configure Windows for SQL Server and Ansible
locals {
  bootstrap_ps1 = <<EOF
<powershell>
# Initial configuration script for Windows Server

# Enable WinRM for Ansible
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file

# Firewall configurations for SQL Server
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
New-NetFirewallRule -DisplayName "SQL Server Browser" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow

# Configure Windows to allow Ansible connections
Set-Item -Path WSMan:\\localhost\\Service\\Auth\\Basic -Value $true
Set-Item -Path WSMan:\\localhost\\Service\\AllowUnencrypted -Value $true

# Create directories for SQL Server
New-Item -Path "C:\\SQLData" -ItemType Directory -Force
New-Item -Path "C:\\SQLLogs" -ItemType Directory -Force
New-Item -Path "C:\\SQLBackup" -ItemType Directory -Force

# Install Windows features necessary for SQL Server
Install-WindowsFeature -Name NET-Framework-Core

# Create a file to indicate bootstrap is complete
New-Item -Path C:\\bootstrap_complete.txt -ItemType File -Value ""
</powershell>
EOF
}

# Create a public IP address
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  domain_name_label   = lower(var.vm_name)
}

# Create a network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create the Windows VM
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]
  custom_data           = base64encode(local.bootstrap_ps1)
  provision_vm_agent    = true

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Create a data disk for SQL Server
resource "azurerm_managed_disk" "data_disk" {
  name                 = "${var.vm_name}-datadisk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
}

# Attach the data disk to the VM
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}

# VM Extension for Custom Script
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "${var.vm_name}-customscript"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File C:\\Windows\\Temp\\bootstrap.ps1"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"]
    }
PROTECTED_SETTINGS

  depends_on = [azurerm_windows_virtual_machine.vm]
}
