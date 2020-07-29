output "saplibrary" {
  value = data.azurerm_storage_account.saplibrary
}

output "file_share_name" {
  value = local.file_share_name
}

output "storagecontainer-sapbits" {
  value = local.blob_container_exists ? data.azurerm_storage_container.storagecontainer-sapbits[0] : null
}
