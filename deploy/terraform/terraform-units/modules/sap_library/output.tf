output "tfstate_storage_account" {
  value = local.sa_tfstate_name
}

output "sapbits_storage_account_name" {
  value = local.sa_sapbits_name
}

output "sapbits_sa_resource_group_name" {
  value = local.rg_name
}

output "storagecontainer_tfstate" {
  value = local.sa_tfstate_container_name
}

output "storagecontainer_sapbits_name" {
  value = local.storagecontainer_sapbits_name
}

output "fileshare_sapbits_name" {
  value = local.fileshare_sapbits_name
}

output "random_id" {
  value = random_id.post_fix.hex
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

output "tfstate_resource_id" {
  value = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].id : azurerm_storage_account.storage_tfstate[0].id
}

output "storagecontainer_ansible" {
  value = local.sa_ansible_container_name
}
