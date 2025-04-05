output "instance_id" {
  description = "ID of the Windows VM instance"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "public_ip" {
  description = "Public IP address of the Windows VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "private_ip" {
  description = "Private IP address of the Windows VM"
  value       = azurerm_network_interface.nic.private_ip_address
}
