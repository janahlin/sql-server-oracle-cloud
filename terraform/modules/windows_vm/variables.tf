variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain for the VM"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet"
  type        = string
}

variable "image_id" {
  description = "OCID of the Windows image"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "SSH public key for Windows VM"
  type        = string
}

variable "vm_display_name" {
  description = "Display name for the VM"
  type        = string
}

variable "shape" {
  description = "Shape of the VM"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  description = "Memory in GBs"
  type        = number
  default     = 1
}
