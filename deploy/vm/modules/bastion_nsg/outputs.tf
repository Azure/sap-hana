output "nsg_id" {
  value = "${var.isLinux ? element(concat(azurerm_network_security_group.linux_group.*.id, list("")), 0): element(concat(azurerm_network_security_group.windows_group.*.id, list("")), 0)}"
}
