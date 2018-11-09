output "nsg_id" {
  value = "${data.azurerm_network_security_group.nsg_info.id}"
}

output "vnet_subnets" {
  value = "${module.vnet.vnet_subnets}"
}

output "vnet_name" {
  value = "${module.vnet.vnet_name}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.hana-resource-group.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.hana-resource-group.location}"
}
