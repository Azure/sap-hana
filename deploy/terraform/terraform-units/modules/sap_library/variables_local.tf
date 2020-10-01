// Input arguments 
variable naming {
  description = "naming convention"
}

locals {

  storageaccount_names = var.naming.storageaccount_names.LIBRARY
  keyvault_names       = var.naming.keyvault_names.LIBRARY
  resource_suffixes    = var.naming.resource_suffixes

  // Infrastructure
  var_infra = try(var.infrastructure, {})

  // Region
  region = try(local.var_infra.region, "")
  prefix = try(local.var_infra.resource_group.name, var.naming.prefix.LIBRARY)

  // Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_exists = try(local.var_rg.is_existing, false)
  rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
  rg_name   = try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.library-rg))

  // Storage account for sapbits
  sa_sapbits_arm_id                   = try(var.storage_account_sapbits.arm_id, "")
  sa_sapbits_exists                   = length(local.sa_sapbits_arm_id) > 0 ? true : false
  sa_sapbits_name                     = local.sa_sapbits_exists ? split("/", local.sa_sapbits_arm_id)[8] : local.storageaccount_names.library_storageaccount_name
  sa_sapbits_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_tier, "Standard")
  sa_sapbits_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_replication_type, "LRS")
  sa_sapbits_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_kind, "StorageV2")
  sa_sapbits_enable_secure_transfer   = true

  // File share for sapbits
  sa_sapbits_file_share_enable = try(var.storage_account_sapbits.file_share.enable_deployment, true)
  sa_sapbits_file_share_exists = try(var.storage_account_sapbits.file_share.is_existing, false)
  sa_sapbits_file_share_name   = try(var.storage_account_sapbits.file_share.name, "sapbits")

  // Blob container for sapbits
  sa_sapbits_blob_container_enable = try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, true)
  sa_sapbits_blob_container_exists = try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false)
  sa_sapbits_blob_container_name   = try(var.storage_account_sapbits.sapbits_blob_container.name, "sapbits")
  sa_sapbits_container_access_type = "private"

  // Storage account for terraform state files
  sa_tfstate_arm_id                   = try(var.storage_account_tfstate.arm_id, "")
  sa_tfstate_exists                   = length(local.sa_tfstate_arm_id) > 0 ? true : false
  sa_tfstate_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
  sa_tfstate_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
  sa_tfstate_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
  sa_tfstate_container_access_type    = "private"
  sa_tfstate_name                     = local.sa_tfstate_exists ? split("/", local.sa_tfstate_arm_id)[8] : local.storageaccount_names.terraformstate_storageaccount_name

  sa_tfstate_enable_secure_transfer  = true
  sa_tfstate_delete_retention_policy = 7
  sa_tfstate_container_exists        = try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
  sa_tfstate_container_name          = "tfstate"
}

// Output objects 
locals {
  rg_library               = local.rg_exists ? data.azurerm_resource_group.library[0] : azurerm_resource_group.library[0]
  sa_tfstate               = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0] : azurerm_storage_account.storage_tfstate[0]
  sa_sapbits               = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0] : azurerm_storage_account.storage_sapbits[0]
  storagecontainer_tfstate = local.sa_tfstate_container_exists ? data.azurerm_storage_container.storagecontainer_tfstate[0] : azurerm_storage_container.storagecontainer_tfstate[0]
  storagecontainer_sapbits = ! local.sa_sapbits_blob_container_enable ? null : (local.sa_sapbits_blob_container_exists ? data.azurerm_storage_container.storagecontainer_sapbits[0] : azurerm_storage_container.storagecontainer_sapbits[0])
  fileshare_sapbits_name   = local.sa_sapbits_file_share_enable ? local.sa_sapbits_file_share_name : null
}
