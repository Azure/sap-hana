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

output "sid_kv_user" {
  value = azurerm_key_vault.sid_kv_user
}

output "sid_kv_prvt" {
  value = azurerm_key_vault.sid_kv_prvt
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
output "sid_kv_user_msi" {
  value = azurerm_key_vault_access_policy.sid_kv_user_msi
}
