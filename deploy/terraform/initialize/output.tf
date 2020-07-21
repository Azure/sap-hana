output "sap-library-resource-group-name" {
  value = module.sap_library.rgName
}

output "tfstate-storage-endpoint" {
  value = module.sap_library.tfstateBlobEndpoint
}

output "sapbits-storage-endpoint" {
  value = module.sap_library.sapbitsBlobEndpoint
}
