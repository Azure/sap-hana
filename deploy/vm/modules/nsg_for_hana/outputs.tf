output "nsg-id" {
  value = "${azurerm_network_security_group.sap-nsg.*.id}"
}
