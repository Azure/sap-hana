output "tfstate_storage_account" {
  value = local.sa_tfstate_name
}

output "sapbits_storage_account" {
  value = local.sa_sapbits_name
}

output "storagecontainer_tfstate" {
  value = local.sa_tfstate_container_name
}

output "storagecontainer_sapbits" {
  value = local.storagecontainer_sapbits
}

output "fileshare_sapbits_name" {
  value = local.fileshare_sapbits_name
}
