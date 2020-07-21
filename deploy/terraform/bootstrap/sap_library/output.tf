output "sap-library-resource-group-name" {
  value = module.sap_library.rgName
}

output "tfstate-storage-account-name" {
    value = module.sap_library.tfstate-storage-account-name
}

output "sapbits-storage-account-name" {
    value = module.sap_library.sapbits-storage-account-name
}
