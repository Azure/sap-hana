output "fqdn" {
  value = "${azurerm_public_ip.pip.fqdn}"
}

output "nic_id" {
  value = "${azurerm_network_interface.nic.id}"
}
