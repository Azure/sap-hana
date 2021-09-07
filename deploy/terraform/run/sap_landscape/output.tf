output "vnet_sap_arm_id" {
  value = try(module.sap_landscape.vnet_sap[0].id, "")
}

output "landscape_key_vault_user_arm_id" {
  value = try(module.sap_landscape.kv_user, "")
}

output "landscape_key_vault_private_arm_id" {
  value = try(module.sap_landscape.kv_prvt, "")
}

output "landscape_key_vault_spn_arm_id" {
  value = local.spn_key_vault_arm_id
}

output "sid_public_key_secret_name" {
  value = try(module.sap_landscape.sid_public_key_secret_name, "")
}

output "iscsi_private_ip" {
  value = try(module.sap_landscape.nics_iscsi[*].private_ip_address, [])
}
output "sid_username_secret_name" {
  value = module.sap_landscape.sid_username_secret_name
}
output "sid_password_secret_name" {
  value = try(module.sap_landscape.sid_password_secret_name, "")
}

output "iscsi_authentication_type" {
  value = try(module.sap_landscape.iscsi_authentication_type, "")
}

output "iscsi_authentication_username" {
  value = try(module.sap_landscape.iscsi_authentication_username, "")
}

output "storageaccount_name" {
  value = try(module.sap_landscape.storageaccount_name, "")
}

output "storageaccount_rg_name" {
  value = try(module.sap_landscape.storageaccount_rg_name, "")
}

// Output for DNS
output "dns_info_iscsi" {
  value = module.sap_landscape.dns_info_vms
}

output "route_table_id" {
  value = module.sap_landscape.route_table_id
}

output "automation_version" {
  value = local.version_label
}

//Witness
output "witness_storage_account" {

  value = module.sap_landscape.witness_storage_account
}

output "witness_storage_account_key" {
  sensitive = true
  value     = module.sap_landscape.witness_storage_account_key
}

output "admin_subnet_id" {
  value = module.sap_landscape.admin_subnet_id
}

output "app_subnet_id" {
  value = module.sap_landscape.app_subnet_id
}

output "db_subnet_id" {
  value = module.sap_landscape.db_subnet_id
}

output "web_subnet_id" {
  value = module.sap_landscape.admin_subnet_id
}


output "admin_nsg_id" {
  value = module.sap_landscape.admin_nsg_id
}

output "app_nsg_id" {
  value = module.sap_landscape.app_nsg_id
}

output "db_nsg_id" {
  value = module.sap_landscape.db_nsg_id
}

output "web_nsg_id" {
  value = module.sap_landscape.admin_nsg_id
}

output "ANF_pool_settings" {
  value = module.sap_landscape.ANF_pool_settings
}


output "dns_label" {
  value = var.dns_label
}

output "spn_kv_id" {
  value = local.spn_key_vault_arm_id
}
