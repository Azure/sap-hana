output "nics_jumpboxes_linux" {
  value = azurerm_network_interface.jump_linux
}

output "nics_jumpboxes_windows" {
  value = azurerm_network_interface.jump_win
}

output "public_ips_jumpboxes_linux" {
  value = azurerm_public_ip.jump_linux
}

output "public_ips_jumpboxes_windows" {
  value = azurerm_public_ip.jump_win
}

output "jumpboxes_linux" {
  value = local.vm_jump_linux
}

output "vm_windows" {
  value = azurerm_windows_virtual_machine.jump_win
}
