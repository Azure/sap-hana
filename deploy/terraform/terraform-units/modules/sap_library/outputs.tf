output rgName { 
    value = azurerm_resource_group.library[0].name 
}
output tfstateBlobEndpoint {
    value = azurerm_storage_account.storage-tfstate[0].primary_blob_endpoint 
}
output sapbitsBlobEndpoint { 
    value = azurerm_storage_account.storage-sapbits[0].primary_blob_endpoint 
}
