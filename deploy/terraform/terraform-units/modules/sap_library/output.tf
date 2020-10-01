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

output "random_id" {
  value = random_id.post_fix.hex
}
