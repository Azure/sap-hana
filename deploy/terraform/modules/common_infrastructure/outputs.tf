output "resource-group" {
  value = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group : azurerm_resource_group.resource-group
}

output "vnet-sap" {
  value = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap : azurerm_virtual_network.vnet-sap
}

output "subnet-mgmt" {
  value = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? data.azurerm_subnet.subnet-mgmt : azurerm_subnet.subnet-mgmt
}

output "nsg-mgmt" {
  value = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? data.azurerm_network_security_group.nsg-mgmt : azurerm_network_security_group.nsg-mgmt
}

output "storage-bootdiag" {
  value = azurerm_storage_account.storage-bootdiag
}

output "storage-sapbits" {
  value = var.software.storage_account_sapbits.is_existing ? data.azurerm_storage_account.storage-sapbits : azurerm_storage_account.storage-sapbits
}

output "random-id" {
  value = random_id.random-id
}

output "nics-iscsi" {
  value = azurerm_network_interface.iscsi
}

output "ppg" {
  value = var.infrastructure.ppg.is_existing ? data.azurerm_proximity_placement_group.ppg : azurerm_proximity_placement_group.ppg
}
