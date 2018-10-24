output "nsg_id" {
  value = "${element( concat(module.nsg.nsg-id, list(var.use_existing_nsg)),0)}"
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
