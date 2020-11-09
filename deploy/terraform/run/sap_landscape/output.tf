output "vnet_sap_arm_id" {
  value = try(module.sap_landscape.vnet_sap[0].id, "")
}

output "landscape_key_vault_user_arm_id" {
  value = try(module.sap_landscape.kv_user[0].id, "")
}

output "sid_public_key_secret_name" {
  value = try(module.sap_landscape.sid_public_key_secret_name, "")
}

output "iscsi_private_ip" {
  value = try(module.sap_landscape.nics_iscsi[*].private_ip_address, [])
}

output "landscape_infrastructure" {
  value = try(module.sap_landscape.infrastructure_w_defaults, {})
}
