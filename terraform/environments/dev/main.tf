terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Local values - used to satisfy lint requirements
locals {
  # Store SSH key to satisfy linter - not used in Windows VM but kept for deployment scripts
  ssh_key = var.ssh_public_key
}

# Resource Group
resource "azurerm_resource_group" "sql_server" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "sql_server" {
  name                = "sql-server-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sql_server.location
  resource_group_name = azurerm_resource_group.sql_server.name
}

# Subnet
resource "azurerm_subnet" "sql_server" {
  name                 = "sql-server-subnet"
  resource_group_name  = azurerm_resource_group.sql_server.name
  virtual_network_name = azurerm_virtual_network.sql_server.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "sql_server" {
  name                = "sql-server-nsg"
  location            = azurerm_resource_group.sql_server.location
  resource_group_name = azurerm_resource_group.sql_server.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SQL"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "sql_server" {
  name                = "sql-server-ip"
  location            = azurerm_resource_group.sql_server.location
  resource_group_name = azurerm_resource_group.sql_server.name
  allocation_method   = "Dynamic"
  domain_name_label   = "sqlserver-${random_string.suffix.result}"
}

# Generate a random suffix for the DNS name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Network Interface
resource "azurerm_network_interface" "sql_server" {
  name                = "sql-server-nic"
  location            = azurerm_resource_group.sql_server.location
  resource_group_name = azurerm_resource_group.sql_server.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sql_server.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sql_server.id
  }
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "sql_server" {
  network_interface_id      = azurerm_network_interface.sql_server.id
  network_security_group_id = azurerm_network_security_group.sql_server.id
}

# Windows VM
resource "azurerm_windows_virtual_machine" "sql_server" {
  name                = "sqlserver-dev"
  resource_group_name = azurerm_resource_group.sql_server.name
  location            = azurerm_resource_group.sql_server.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.sql_server.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  # Enable WinRM
  winrm_listener {
    protocol = "Http"
  }

  custom_data = base64encode(<<CUSTOM_DATA
<powershell>
# Enable WinRM
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Enable WinRM HTTPS
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force

# Open firewall ports
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
</powershell>
CUSTOM_DATA
  )
}

# Data disk for SQL Server
resource "azurerm_managed_disk" "sql_data" {
  name                 = "sql-data-disk"
  location             = azurerm_resource_group.sql_server.location
  resource_group_name  = azurerm_resource_group.sql_server.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
}

# Attach data disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "sql_data" {
  managed_disk_id    = azurerm_managed_disk.sql_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.sql_server.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Generate inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl",
    {
      vm_ip      = azurerm_public_ip.sql_server.ip_address
      admin_user = var.admin_username
      admin_pass = var.admin_password
      ssh_key    = local.ssh_key
    }
  )
  filename = "${path.module}/../../../ansible/inventory/hosts.yml"

  # Wait for the public IP to be assigned
  depends_on = [
    azurerm_public_ip.sql_server,
    azurerm_windows_virtual_machine.sql_server
  ]
}

# Output the public IP address
output "sql_server_public_ip" {
  value       = azurerm_public_ip.sql_server.ip_address
  description = "The public IP address of the SQL Server VM"
}

output "sql_server_fqdn" {
  value       = azurerm_public_ip.sql_server.fqdn
  description = "The fully qualified domain name of the SQL Server VM"
}

output "sql_server_connection_string" {
  value       = "Server=${azurerm_public_ip.sql_server.fqdn},1433;Initial Catalog=TestDB;User Id=remote_test;Password=ChangeThisPasswordOnFirstLogin!;"
  description = "SQL Server connection string"
}

output "rdp_connection" {
  value       = "mstsc /v:${azurerm_public_ip.sql_server.ip_address}"
  description = "RDP connection command"
}
