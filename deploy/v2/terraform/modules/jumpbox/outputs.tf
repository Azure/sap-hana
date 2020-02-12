output "nics-jumpboxes-linux" {
  value = azurerm_network_interface.nic-linux
}

output "nics-jumpboxes-windows" {
  value = azurerm_network_interface.nic-windows
}

output "public-ips-jumpboxes-linux" {
  value = azurerm_public_ip.public-ip-linux
}

output "public-ips-jumpboxes-windows" {
  value = azurerm_public_ip.public-ip-windows
}

output "rti-info" {
  value = local.rti-info[0]
}

# Workaround to create dependency betweeen ../main.tf ansible_execution and module jumpbox
output "prepare-rti" {
  value = null_resource.prepare-rti
}

output "vm-windows" {
  value = azurerm_virtual_machine.vm-windows
}
