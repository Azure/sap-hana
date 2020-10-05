output "tfstate_storage_account" {
  value = local.sa_tfstate
}

output "sapbits_storage_account" {
  value = local.sa_sapbits
}

output "storagecontainer_tfstate" {
  value = local.storagecontainer_tfstate
}

output "storagecontainer_sapbits" {
  value = local.storagecontainer_sapbits
}

output "fileshare_sapbits_name" {
  value = local.fileshare_sapbits_name
}

output "user_vault_name" {
  value = azurerm_key_vault.kv_user.name
}

output "remote_state_resource_group_name" {
  value = local.rg_name
}

output "remote_state_storage_account_name" {
  value = local.sa_tfstate_name
}

output "remote_state_container_name" {
  value = local.sa_tfstate_container_name
}
