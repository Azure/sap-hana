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
