output "tfstate_storage_account" {
  value = local.sa_tfstate
}

output "sapbits_storage_account" {
  value = local.sa_sapbits
}

output "storagecontainer_saplibrary" {
  value = local.storagecontainer_saplibrary
}

output "storagecontainer_sapbits" {
  value = local.storagecontainer_sapbits
}

output "fileshare_sapbits_name" {
  value = local.fileshare_sapbits_name
}
