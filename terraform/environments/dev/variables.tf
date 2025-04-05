# Azure Authentication Variables
variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "client_id" {
  description = "The Azure service principal client ID"
  type        = string
}

variable "client_secret" {
  description = "The Azure service principal client secret"
  type        = string
  sensitive   = true
}

# Azure Configuration Variables
variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "sql-server-rg"
}

# VM Configuration Variables
variable "admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "The size of the Windows VM"
  type        = string
  default     = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "SSH public key for authentication (used for deployment scripts)"
  type        = string
}
