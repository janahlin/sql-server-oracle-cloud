# Oracle Cloud Authentication
variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "Oracle Cloud region"
  type        = string
}

variable "compartment_id" {
  description = "OCI Compartment ID where resources will be created"
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain for the VM"
  type        = string
}

variable "windows_image_id" {
  description = "Windows Server 2019 Image ID"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for remote access"
  type        = string
}
