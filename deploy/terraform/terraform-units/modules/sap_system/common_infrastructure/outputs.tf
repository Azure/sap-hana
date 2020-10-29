output "resource-group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource-group : azurerm_resource_group.resource-group
}

output "vnet-sap" {
  value = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap : azurerm_virtual_network.vnet-sap
}

output "subnet-mgmt" {
  value = var.subnet-mgmt
}

output "nsg-mgmt" {
  value = var.nsg-mgmt
}

output "storage-bootdiag" {
  value = azurerm_storage_account.storage-bootdiag
}

output "nics-iscsi" {
  value = azurerm_network_interface.iscsi
}

output "ppg" {
  value = local.ppg_exists ? data.azurerm_proximity_placement_group.ppg : azurerm_proximity_placement_group.ppg
}

output "infrastructure_w_defaults" {
  value = local.infrastructure
}

output "software_w_defaults" {
  value = local.software
}

output "random_id" {
  value = random_id.random_id.hex
}

output "admin_subnet" {
  value = local.sub_admin_exists ? data.azurerm_subnet.admin[0] : azurerm_subnet.admin[0]
}
