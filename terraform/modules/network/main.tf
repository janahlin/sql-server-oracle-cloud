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

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vnet_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
}

# Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow RDP connections from specific IP ranges only
  # WARNING: Replace 0.0.0.0/0 with your specific IP range for better security
  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "0.0.0.0/0" # SECURITY RISK: Restrict to specific IP ranges
    destination_address_prefix = "*"
  }

  # Allow WinRM connections from specific IP ranges only
  # WARNING: Replace 0.0.0.0/0 with your specific IP range for better security
  security_rule {
    name                       = "WinRM"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = "0.0.0.0/0" # SECURITY RISK: Restrict to specific IP ranges
    destination_address_prefix = "*"
  }

  # Allow SQL Server access from specific IP ranges only
  # WARNING: Replace 0.0.0.0/0 with your specific IP range for better security
  security_rule {
    name                       = "SQLServer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "0.0.0.0/0" # SECURITY RISK: Restrict to specific IP ranges
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}
