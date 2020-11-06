output "saplandscape_kv_user_arm_id" {
  value = try(module.sap_landscape.kv_user.id, "")
}

output "sid_public_key_secret_name" {
  value = try(module.sap_landscape.sid_public_key_secret_name, "")
}
