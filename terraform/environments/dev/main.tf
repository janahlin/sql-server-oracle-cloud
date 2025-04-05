terraform {
  required_version = ">= 1.0.0"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

module "network" {
  source         = "../../modules/network"
  compartment_id = var.compartment_id
  vcn_name       = "sql-server-vcn"
  vcn_cidr       = "10.0.0.0/16"
}

module "windows_vm" {
  source              = "../../modules/windows_vm"
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  subnet_id           = module.network.subnet_id
  image_id            = var.windows_image_id
  ssh_authorized_keys = var.ssh_public_key
  vm_display_name     = "sqlserver-dev"
}

# Output the public IP of the Windows VM
output "windows_vm_public_ip" {
  value = module.windows_vm.public_ip
}
