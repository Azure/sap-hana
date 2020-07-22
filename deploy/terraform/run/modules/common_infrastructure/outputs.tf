output "resource-group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource-group : azurerm_resource_group.resource-group
}

output "vnet-sap" {
  value = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap : azurerm_virtual_network.vnet-sap
}

output "subnet-mgmt" {
  value = local.sub_mgmt_exists ? data.azurerm_subnet.subnet-mgmt : azurerm_subnet.subnet-mgmt
}

output "nsg-mgmt" {
  value = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg-mgmt : azurerm_network_security_group.nsg-mgmt
}

output "storage-bootdiag" {
  value = azurerm_storage_account.storage-bootdiag
}

output "storage-sapbits" {
  value = local.sa_sapbits_exists ? data.azurerm_storage_account.storage-sapbits : azurerm_storage_account.storage-sapbits
}

output "random-id" {
  value = random_id.random-id
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
