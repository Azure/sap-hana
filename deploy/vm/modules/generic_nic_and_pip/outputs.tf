output "fqdn" {
  description = "The fully qualified domain name associated with the public ip that was created."
  value       = "${azurerm_public_ip.pip.fqdn}"
}

output "nic_id" {
  description = "The id of the network interface card will be needed to attach it to the vm."
  value       = "${azurerm_network_interface.nic.id}"
}
