#!/bin/bash

# Back up the original file
cp terraform/modules/windows_vm/main.tf terraform/modules/windows_vm/main.tf.bak2

cat > terraform/modules/windows_vm/main.tf << 'ENDOFFILE'
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
  default     = "VM.Standard2.1"
}

# Simplified version
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
  }

  preserve_boot_volume = false
}
ENDOFFILE

# Update environment variables to use a different shape
cat > scripts/update_tfvars.sh << 'ENDOFFILE'
#!/bin/bash

# Parse the existing terraform.tfvars.json file
if [ -f terraform/environments/dev/terraform.tfvars.json ]; then
  # Change the shape to VM.Standard2.1
  jq '.shape = "VM.Standard2.1"' terraform/environments/dev/terraform.tfvars.json > /tmp/terraform.tfvars.json
  mv /tmp/terraform.tfvars.json terraform/environments/dev/terraform.tfvars.json
  echo "Updated shape in terraform.tfvars.json"
else
  echo "No terraform.tfvars.json found to update"
fi
ENDOFFILE

chmod +x scripts/update_tfvars.sh
./scripts/update_tfvars.sh

echo "Simplified VM configuration to use only essential parameters."
echo "Try running the deployment again:"
echo "./scripts/deploy.sh"
