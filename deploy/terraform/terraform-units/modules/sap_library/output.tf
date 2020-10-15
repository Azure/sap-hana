output "tfstate_storage_account" {
  value = local.sa_tfstate
}

output "sapbits_storage_account_name" {
  value = local.sa_sapbits_name
}

output "sapbits_sa_resource_group_name" {
  value = local.rg_name
}

output "storagecontainer_tfstate" {
  value = local.storagecontainer_tfstate
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
