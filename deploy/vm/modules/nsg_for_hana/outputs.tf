output "nsg-id" {
  value = "${azurerm_network_security_group.sap-nsg.*.id}"
}

output "nsg-name" {
  value = "${element(concat(azurerm_network_security_group.sap-nsg.*.name,list(local.empty_string)),0)}"
}
