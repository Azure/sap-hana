output "tfstate_storage_account" {
    value = local.sa_tfstate
}

output "sapbits_storage_account" {
    value = local.sa_sapbits
}

output "storagecontainer_sapsystem" {
    value = local.storagecontainer_sapsystem
}

output "storagecontainer_saplandscape" {
    value = local.storagecontainer_saplandscape
}

output "storagecontainer_deployer" {
    value = local.storagecontainer_deployer
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
