/*
Description:

  Define local variables.
*/

// Input arguments 
variable naming {
  description = "naming convention"
}

variable "deployer_tfstate" {
  description = "terraform.tfstate of deployer"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable "region_mapping" {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"

  # 28 Regions 

  default = {
    westus             = "weus"
    westus2            = "wus2"
    centralus          = "ceus"
    eastus             = "eaus"
    eastus2            = "eus2"
    northcentralus     = "ncus"
    southcentralus     = "scus"
    westcentralus      = "wcus"
    northeurope        = "noeu"
    westeurope         = "weeu"
    eastasia           = "eaas"
    southeastasia      = "seas"
    brazilsouth        = "brso"
    japaneast          = "jpea"
    japanwest          = "jpwe"
    centralindia       = "cein"
    southindia         = "soin"
    westindia          = "wein"
    uksouth2           = "uks2"
    uknorth            = "ukno"
    canadacentral      = "cace"
    canadaeast         = "caea"
    australiaeast      = "auea"
    australiasoutheast = "ause"
    uksouth            = "ukso"
    ukwest             = "ukwe"
    koreacentral       = "koce"
    koreasouth         = "koso"
  }
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

  rg_name = try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.library_rg))

  // Storage account for sapbits
  sa_sapbits_arm_id = try(var.storage_account_sapbits.arm_id, "")
  sa_sapbits_exists = length(local.sa_sapbits_arm_id) > 0 ? true : false
  sa_sapbits_name   = local.sa_sapbits_exists ? split("/", local.sa_sapbits_arm_id)[8] : local.storageaccount_names.library_storageaccount_name

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

  // Storage account for tfstate
  sa_tfstate_arm_id                   = try(var.storage_account_tfstate.arm_id, "")
  sa_tfstate_exists                   = length(local.sa_tfstate_arm_id) > 0 ? true : false
  sa_tfstate_account_tier             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
  sa_tfstate_account_replication_type = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
  sa_tfstate_account_kind             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
  sa_tfstate_container_access_type    = "private"
  sa_tfstate_name                     = local.sa_tfstate_exists ? split("/", local.sa_tfstate_arm_id)[8] : local.storageaccount_names.terraformstate_storageaccount_name
  sa_tfstate_enable_secure_transfer   = true
  sa_tfstate_delete_retention_policy  = 7

  sa_tfstate_container_exists = try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
  sa_tfstate_container_name   = try(var.storage_account_sapbits.tfstate_blob_container.name, "tfstate")

  // deployer
  deployer                = try(var.deployer, {})
  deployer_environment    = try(local.deployer.environment, "")
  deployer_location_short = try(var.region_mapping[local.deployer.region], "unkn")
  deployer_vnet           = try(local.deployer.vnet, "")
  deployer_prefix         = upper(format("%s-%s-%s", local.deployer_environment, local.deployer_location_short, substr(local.deployer_vnet, 0, 7)))

  // Comment out code with users.object_id for the time being.
  // deployer_users_id = try(local.deployer.users.object_id, [])

  // key vault for saplibrary
  // Post fix for all deployed resources
  postfix         = upper(substr(random_id.post_fix.hex, 0, 4))
  environment     = try(var.infrastructure.environment, "")
  location_short  = try(var.region_mapping[local.region], "unkn")
  kv_prefix       = upper(format("%s%s", substr(local.environment, 0, 5), local.location_short))
  kv_private_name = format("%sSAPLIBprvt%s", local.kv_prefix, local.postfix)
  kv_user_name    = format("%sSAPLIBuser%s", local.kv_prefix, local.postfix)

  // Current service principal
  service_principal = try(var.service_principal, {})

  // deployer terraform.tfstate
  deployer_tfstate          = var.deployer_tfstate
  deployer_msi_principal_id = local.deployer_tfstate.outputs.deployer_uai.principal_id

}

locals {
  rg_library_location           = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  storagecontainer_sapbits_name = local.sa_sapbits_blob_container_enable ? local.sa_sapbits_blob_container_name : null
  fileshare_sapbits_name        = local.sa_sapbits_file_share_enable ? local.sa_sapbits_file_share_name : null
}
