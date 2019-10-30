output "nics-linux-jumpboxes" {
  value = azurerm_network_interface.nic-linux
}

output "nics-windows-jumpboxes" {
  value = azurerm_network_interface.nic-windows
}
