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

output "kv_user" {
  value = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

  # TODO Add this back when we separate the usage
# output "kv_prvt" {
#   value = local.prvt_kv_exist ? data.azurerm_key_vault.kv_prvt[0].id : azurerm_key_vault.kv_prvt[0].id
# }

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

output "route_table_id" {
  value = local.vnet_sap_exists ? "" : azurerm_route_table.rt[0].id
}

//Witness Info
output "witness_storage_account" {
  value = length(var.witness_storage_account.arm_id) > 0 ? (
    split("/", var.witness_storage_account.arm_id)[8]) : (
    local.witness_storageaccount_name
  )
}

output "witness_storage_account_key" {
  sensitive = true
  value = length(var.witness_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.witness_storage[0].primary_access_key) : (
    azurerm_storage_account.witness_storage[0].primary_access_key
  )
}

output "admin_subnet_id" {
  value = local.sub_admin_defined ? (
    local.sub_admin_existing ? local.sub_admin_arm_id : azurerm_subnet.admin[0].id) : (
    ""
  )
}

output "app_subnet_id" {
  value = local.sub_app_defined ? (
    local.sub_app_existing ? local.sub_app_arm_id : azurerm_subnet.app[0].id) : (
    ""
  )
}

output "db_subnet_id" {
  value = local.sub_db_defined ? (
    local.sub_db_existing ? local.sub_db_arm_id : azurerm_subnet.db[0].id) : (
    ""
  )
}

output "web_subnet_id" {
  value = local.sub_web_defined ? (
    local.sub_web_existing ? local.sub_web_arm_id : azurerm_subnet.web[0].id) : (
    ""
  )
}


output "anf_subnet_id" {
  value = local.sub_anf_defined ? (
    local.sub_anf_existing ? local.sub_anf_arm_id : azurerm_subnet.anf[0].id) : (
    ""
  )
}

output "admin_nsg_id" {
  value = local.sub_admin_defined ? (
    local.sub_admin_nsg_exists ? local.sub_admin_nsg_arm_id : azurerm_network_security_group.admin[0].id) : (
    ""
  )
}

output "app_nsg_id" {
  value = local.sub_app_defined ? (
    local.sub_app_nsg_exists ? local.sub_app_nsg_arm_id : azurerm_network_security_group.app[0].id) : (
    ""
  )
}

output "db_nsg_id" {
  value = local.sub_db_defined ? (
    local.sub_db_nsg_exists ? local.sub_db_nsg_arm_id : azurerm_network_security_group.db[0].id) : (
    ""
  )
}

output "web_nsg_id" {
  value = local.sub_web_defined ? (
    local.sub_web_nsg_exists ? local.sub_web_nsg_arm_id : azurerm_network_security_group.web[0].id) : (
    ""
  )
}


output "ANF_pool_settings" {
  value = var.ANF_settings.use ? {
    use_ANF = true
    account_name = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
      data.azurerm_netapp_account.workload_netapp_account[0].name) : (
      azurerm_netapp_account.workload_netapp_account[0].name
    )
    pool_name     = azurerm_netapp_pool.workload_netapp_pool[0].name
    service_level = azurerm_netapp_pool.workload_netapp_pool[0].service_level
    size_in_tb    = azurerm_netapp_pool.workload_netapp_pool[0].size_in_tb
    subnet_id = local.sub_anf_defined ? (
      local.sub_anf_existing ? local.sub_anf_arm_id : azurerm_subnet.anf[0].id) : (
      ""
    )
    resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
    location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
    } : {
    use_ANF = false
  }
}
