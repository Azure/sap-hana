output "tfstate_storage_account" {
    value = module.sap_library.sapbits_storage_account
}

output "sapbits_storage_account" {
    value = module.sap_library.sapbits_storage_account
}

output "storagecontainer_sapsystem" {
    value = module.sap_library.storagecontainer_sapsystem
}

output "storagecontainer_saplandscape" {
    value = module.sap_library.storagecontainer_saplandscape
}

output "storagecontainer_deployer" {
    value = module.sap_library.storagecontainer_deployer
}

output "storagecontainer_saplibrary" {
    value = module.sap_library.storagecontainer_saplibrary
}

output "storagecontainer_sapbits" {
    value = module.sap_library.storagecontainer_sapbits
}

output "fileshare_sapbits_name" {
    value = module.sap_library.fileshare_sapbits_name
}
