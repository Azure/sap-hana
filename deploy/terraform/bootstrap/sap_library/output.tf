output "tfstate_storage_account" {
  sensitive = true
  value     = module.sap_library.tfstate_storage_account
}

output "sapbits_storage_account" {
  sensitive = true
  value     = module.sap_library.sapbits_storage_account
}

output "storagecontainer_saplibrary" {
  sensitive = true
  value     = module.sap_library.storagecontainer_saplibrary
}

output "storagecontainer_sapbits" {
  sensitive = true
  value     = module.sap_library.storagecontainer_sapbits
}

output "fileshare_sapbits_name" {
  sensitive = true
  value     = module.sap_library.fileshare_sapbits_name
}
