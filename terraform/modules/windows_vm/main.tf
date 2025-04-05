terraform {
  required_version = ">= 1.0.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}

variable "compartment_id" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet to place the VM in"
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain for the VM"
  type        = string
}

variable "image_id" {
  description = "OCID of the Windows Server image"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "Public SSH key for remote access"
  type        = string
}

variable "vm_display_name" {
  description = "Display name for the VM"
  type        = string
  default     = "sqlserver-dev"
}

variable "shape" {
  description = "Shape/size of the VM"
  type        = string
  default     = "VM.Standard.E2.1.Micro" # Free Tier eligible
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

resource "oci_core_instance" "windows_vm" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.vm_display_name
  shape               = var.shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.vm_display_name}-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    user_data           = base64encode(local.bootstrap_ps1)
  }

  # This is required for the Free Tier shape
  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }

  preserve_boot_volume = false
}
