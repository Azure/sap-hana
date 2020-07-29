output "nics-jumpboxes-linux" {
  value = azurerm_network_interface.jump-linux
}

output "nics-jumpboxes-windows" {
  value = azurerm_network_interface.jump-win
}

output "public-ips-jumpboxes-linux" {
  value = azurerm_public_ip.jump-linux
}

output "public-ips-jumpboxes-windows" {
  value = azurerm_public_ip.jump-win
}

output "jumpboxes-linux" {
  value = local.vm-jump-linux
}

output "vm-windows" {
  value = azurerm_windows_virtual_machine.jump-win
}
