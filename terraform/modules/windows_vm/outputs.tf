output "instance_id" {
  description = "The OCID of the Windows VM instance"
  value       = oci_core_instance.windows_vm.id
}

output "public_ip" {
  description = "The public IP address of the Windows VM"
  value       = oci_core_instance.windows_vm.public_ip
}

output "private_ip" {
  description = "The private IP address of the Windows VM"
  value       = oci_core_instance.windows_vm.private_ip
}
