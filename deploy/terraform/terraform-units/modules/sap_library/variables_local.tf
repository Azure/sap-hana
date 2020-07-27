locals {

    // Infrastructure
    var_infra = try(var.infrastructure, {})

    // Region
    region = try(local.var_infra.region, "eastus")

    // Resource group
    var_rg    = try(local.var_infra.resource_group, {})
    rg_exists = try(local.var_rg.is_existing, false)
    rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
    rg_name   = local.rg_exists ? "" : try(local.var_rg.name, "azure-deployer-rg")

    // Storage account for sapbits
    sa_sapbits_exists                   = try(var.storage_account_sapbits.is_existing, false)
    sa_sapbits_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_tier, "Premium")
    sa_sapbits_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_replication_type, "LRS")
    sa_sapbits_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_kind, "FileStorage")
    sa_sapbits_file_share_name          = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.file_share_name, "bits")
    sa_sapbits_blob_container_name      = "null"
    sa_sapbits_container_access_type    = "blob"
    sa_sapbits_name                     = local.sa_sapbits_exists ? "": "sapbits${random_id.post-fix.hex}"
    sa_sapbits_arm_id                   = local.sa_sapbits_exists ? try(var.storage_account_sapbits.arm_id, "") : ""
    sa_sapbits_enable_secure_transfer   = true

    // Storage account for tfstate, json and deployer
    sa_tfstate_exists                   = try(var.storage_account_tfstate.is_existing, false)
    sa_tfstate_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
    sa_tfstate_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
    sa_tfstate_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
    sa_tfstate_container_access_type    = "private"
    sa_tfstate_name                     = local.sa_sapbits_exists ? "" : "tfstate${random_id.post-fix.hex}"
    sa_tfstate_arm_id                   = local.sa_sapbits_exists ? try(var.storage_account_tfstate.arm_id, "") : ""
    sa_tfstate_enable_secure_transfer   = true
    sa_tfstate_delete_retention_policy  = 7
    sa_tfstate_container_name           = "tfstate"
    sa_json_container_name              = "json"
    sa_deployer_container_name          = "deployer"
    sa_saplibrary_container_name        = "saplibrary"
}
