output "resource_group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource_group : azurerm_resource_group.resource_group
}

output "vnet_sap" {
  value = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap : azurerm_virtual_network.vnet_sap
}

output "storage_bootdiag" {
  value = azurerm_storage_account.storage_bootdiag
}

output "random_id" {
  value = random_id.random_id.hex
}

output "nics_iscsi" {
  value = local.iscsi_count > 0 ? azurerm_network_interface.iscsi[*] : []
}

output "infrastructure_w_defaults" {
  value = local.infrastructure
}

output "kv_user" {
  value = azurerm_key_vault.kv_user
}

output "kv_prvt" {
  value = azurerm_key_vault.kv_prvt
}

output "sid_public_key_secret_name" {
  value = local.enable_landscape_kv ? azurerm_key_vault_secret.sid_pk[0].name : ""
}

output "sid_private_key_secret_name" {
  value = local.enable_landscape_kv ? azurerm_key_vault_secret.sid_ppk[0].name : ""
}
