terraform {
  required_version = ">= 1.0.0"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }
  }
}

# Windows VM Instance
resource "oci_core_instance" "windows_vm" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.vm_display_name
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

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
    user_data           = base64encode(file("${path.module}/scripts/bootstrap.ps1"))
  }

  # Windows VMs need to preserve boot volume on termination
  preserve_boot_volume = false
}

# Remove the extra volume creation for Free Tier compatibility
