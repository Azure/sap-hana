output "resource-group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource-group : azurerm_resource_group.resource-group
}

output "vnet-sap" {
  value = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap : azurerm_virtual_network.vnet-sap
}

output "storage-bootdiag" {
  value = azurerm_storage_account.storage-bootdiag
}

output "random_id" {
  value = random_id.random_id.hex
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

output "admin_subnet" {
  value = ! local.enable_admin_subnet ? null : (local.sub_admin_exists ? data.azurerm_subnet.admin[0] : azurerm_subnet.admin[0])
}

output "sid_kv_user" {
  value = local.enable_sid_deployment ? azurerm_key_vault.sid_kv_user : null
}

output "sid_kv_prvt" {
  value = local.enable_sid_deployment ? azurerm_key_vault.sid_kv_prvt : null
}
