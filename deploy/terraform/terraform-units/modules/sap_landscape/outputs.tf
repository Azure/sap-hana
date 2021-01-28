output "resource_group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource_group : azurerm_resource_group.resource_group
}

output "vnet_sap" {
  value = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap : azurerm_virtual_network.vnet_sap
}

output "random_id" {
  value = random_id.random_id.hex
}

output "nics_iscsi" {
  value = local.iscsi_count > 0 ? (
    azurerm_network_interface.iscsi[*]) : (
    []
  )
}

output "infrastructure_w_defaults" {
  value = local.infrastructure
}

output "kv_user" {
  value = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

output "kv_prvt" {
  value = local.prvt_kv_exist ? data.azurerm_key_vault.kv_prvt[0].id : azurerm_key_vault.kv_prvt[0].id
}

output "sid_public_key_secret_name" {
  value = local.sid_pk_name 
}

output "sid_private_key_secret_name" {
  value = local.sid_ppk_name 
}


output "sid_username_secret_name" {
  value = local.sid_username_secret_name
}
output "sid_password_secret_name" {
  value = local.sid_password_secret_name
}
output "iscsi_authentication_type" {
  value = local.iscsi_auth_type
}
output "iscsi_authentication_username" {
  value = local.iscsi_auth_username
}

output "storageaccount_name" {
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].name) : (
    azurerm_storage_account.storage_bootdiag[0].name
  )
}

output "storageaccount_rg_name" {
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].resource_group_name) : (
    azurerm_storage_account.storage_bootdiag[0].resource_group_name
  )
}


output "storage_bootdiag_endpoint" {
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint) : (
    azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint
  )
}


// Output for DNS
output "dns_info_vms" {
  value = local.iscsi_count > 0 ? zipmap(local.full_iscsiserver_names, azurerm_network_interface.iscsi[*].private_ip_address) : null
}
