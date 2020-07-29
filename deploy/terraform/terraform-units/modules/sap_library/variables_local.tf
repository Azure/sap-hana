// Input arguments 
locals {

    // Infrastructure
    var_infra = try(var.infrastructure, {})

    // Region
    region = try(local.var_infra.region, "eastus")

    // Resource group
    var_rg    = try(local.var_infra.resource_group, {})
    rg_exists = try(local.var_rg.is_existing, false)
    rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
    rg_name   = local.rg_exists ? "" : try(local.var_rg.name, "azure-saplibrary-rg")

    // Storage account for sapbits
    sa_sapbits_exists                   = try(var.storage_account_sapbits.is_existing, false)
    sa_sapbits_name                     = "sapbits${random_id.post_fix.hex}"
    sa_sapbits_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_tier, "Standard")
    sa_sapbits_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_replication_type, "LRS")
    sa_sapbits_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_kind, "StorageV2")
    sa_sapbits_enable_secure_transfer   = true
    sa_sapbits_arm_id                   = local.sa_sapbits_exists ? try(var.storage_account_sapbits.arm_id, "") : ""
    
    // File share for sapbits
    sa_sapbits_file_share_enable        = try(var.storage_account_sapbits.file_share.enable_deployment, false)
    sa_sapbits_file_share_exists        = try(var.storage_account_sapbits.file_share.is_existing, false)
    sa_sapbits_file_share_name          = try(var.storage_account_sapbits.file_share.name, "")
    
    // Blob container for sapbits
    sa_sapbits_blob_container_enable    = try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, false)
    sa_sapbits_blob_container_exists    = try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false)
    sa_sapbits_blob_container_name      = try(var.storage_account_sapbits.sapbits_blob_container.name, "")
    sa_sapbits_container_access_type    = "private"
    
    // Storage account for tfstate, json and deployer
    sa_tfstate_exists                   = try(var.storage_account_tfstate.is_existing, false)
    sa_tfstate_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
    sa_tfstate_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
    sa_tfstate_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
    sa_tfstate_container_access_type    = "private"
    sa_tfstate_name                     = "tfstate${random_id.post_fix.hex}"
    sa_tfstate_arm_id                   = local.sa_sapbits_exists ? try(var.storage_account_tfstate.arm_id, "") : ""
    sa_tfstate_enable_secure_transfer   = true
    sa_tfstate_delete_retention_policy  = 7

    sa_tfstate_container_exists         = try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
    sa_tfstate_container_name           = "tfstate"
    
    sa_json_container_exists            = try(var.storage_account_tfstate.json_blob_container.is_existing, false)
    sa_json_container_name              = "json"
    
    sa_deployer_container_exists        = try(var.storage_account_tfstate.deployer_blob_container.is_existing, false)
    sa_deployer_container_name          = "deployer"
    
    sa_saplibrary_container_exists      = try(var.storage_account_tfstate.saplibrary_blob_container.is_existing, false)
    sa_saplibrary_container_name        = "saplibrary"
}

// Output objects 
locals {
    rg_library                          = local.rg_exists? data.azurerm_resource_group.library[0] : azurerm_resource_group.library[0]
    sa_tfstate                          = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0] : azurerm_storage_account.storage_tfstate[0]
    sa_sapbits                          = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0] : azurerm_storage_account.storage_sapbits[0]
    storagecontainer_tfstate            = local.sa_tfstate_container_exists ? data.azurerm_storage_container.storagecontainer_tfstate[0] : azurerm_storage_container.storagecontainer_tfstate[0]
    storagecontainer_json               = local.sa_json_container_exists ? data.azurerm_storage_container.storagecontainer_json[0] : azurerm_storage_container.storagecontainer_json[0]
    storagecontainer_saplibrary         = local.sa_saplibrary_container_exists ? data.azurerm_storage_container.storagecontainer_saplibrary[0] : azurerm_storage_container.storagecontainer_saplibrary[0]
    storagecontainer_deployer           = local.sa_deployer_container_exists ? data.azurerm_storage_container.storagecontainer_deployer[0] : azurerm_storage_container.storagecontainer_deployer[0]
    storagecontainer_sapbits            = ! local.sa_sapbits_blob_container_enable? null : (local.sa_sapbits_blob_container_exists ? data.azurerm_storage_container.storagecontainer_sapbits[0] : azurerm_storage_container.storagecontainer_sapbits[0])
    fileshare_sapbits_name              = local.sa_sapbits_file_share_enable? local.sa_sapbits_file_share_name : ""
}
