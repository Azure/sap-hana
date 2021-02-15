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
  value = local.user_kv_exist ? data.azurerm_key_vault.kv_user : azurerm_key_vault.kv_user
}

output "kv_prvt" {
  value = local.prvt_kv_exist ? data.azurerm_key_vault.kv_prvt : azurerm_key_vault.kv_prvt
}

output "sid_public_key_secret_name" {
  value = local.enable_landscape_kv ? local.sid_pk_name : ""
}

output "sid_private_key_secret_name" {
  value = local.enable_landscape_kv ? local.sid_ppk_name : ""
}

output "iscsi_authentication_type" {
  value = local.iscsi_auth_type
}

output "iscsi_authentication_username" {
  value = local.iscsi_auth_username
}

output "storageaccount_name" {
  value = azurerm_storage_account.storage_bootdiag.name
}

output "storageaccount_rg_name" {
  value = azurerm_storage_account.storage_bootdiag.resource_group_name
}

// Output for DNS
output "dns_info_vms" {
  value = local.iscsi_count > 0 ? zipmap(local.full_iscsiserver_names, azurerm_network_interface.iscsi[*].private_ip_address) : null
}
