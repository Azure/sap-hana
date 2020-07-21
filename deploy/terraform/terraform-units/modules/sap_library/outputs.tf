output "rgName" { 
    value = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name 
}

output "tfstate-storage-account-name" {
    value = local.sa_tfstate_exists ? data.azurerm_storage_account.storage-tfstate[0].name : azurerm_storage_account.storage-tfstate[0].name 
}

output "sapbits-storage-account-name" {
    value = local.sa_sapbits_exists ? data.azurerm_storage_account.storage-sapbits[0].name : azurerm_storage_account.storage-sapbits[0].name 
}
