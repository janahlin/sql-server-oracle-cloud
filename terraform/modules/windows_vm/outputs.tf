output "instance_id" {
  description = "OCID of the Windows VM instance"
  value       = oci_core_instance.windows_vm.id
}

output "public_ip" {
  description = "Public IP address of the Windows VM"
  value       = oci_core_instance.windows_vm.public_ip
}

output "private_ip" {
  description = "Private IP address of the Windows VM"
  value       = oci_core_instance.windows_vm.private_ip
}
