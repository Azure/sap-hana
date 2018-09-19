output "nsg_id" {
  value = "${module.nsg.nsg-id}"
}

output "vnet_subnets" {
  value = "${module.vnet.vnet_subnets}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.hana-resource-group.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.hana-resource-group.location}"
}
