output "vnet_resource_group_name" {
  value = try(module.sap_landscape.vnet_sap[0].resource_group_name, "")
}

output "vet_sap_name" {
  value = try(module.sap_landscape.vnet_sap[0].name, "")
}

output "landscape_key_vault_user_arm_id" {
  value = try(module.sap_landscape.kv_user[0].id, "")
}

output "sid_public_key_secret_name" {
  value = try(module.sap_landscape.sid_public_key_secret_name, "")
}

output "nics_iscsi" {
  value = try(module.sap_landscape.nics_iscsi[*].private_ip_address, [])
}
