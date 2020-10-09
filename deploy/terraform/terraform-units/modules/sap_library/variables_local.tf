// Input arguments 
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

  // Infrastructure
  var_infra = try(var.infrastructure, {})

  // Region
  region         = try(local.var_infra.region, "")
  environment    = try(var.infrastructure.environment, "")
  location_short = try(var.region_mapping[local.region], "unkn")
  prefix         = upper(format("%s-%s", local.environment, local.location_short))

  // Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_exists = try(local.var_rg.is_existing, false)
  rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
  rg_name   = local.rg_exists ? split("/", local.rg_arm_id)[4] : try(local.var_rg.name, format("%s-SAP_LIBRARY", local.prefix))

  // Storage account for sapbits
  sa_sapbits_exists                   = try(var.storage_account_sapbits.is_existing, false)
  sa_sapbits_name                     = local.sa_sapbits_exists ? split("/", local.sa_sapbits_arm_id)[8] : lower(format("%s%ssaplib%s", substr(local.environment, 0, 5), local.location_short, substr(random_id.post_fix.hex, 0, 4)))
  sa_sapbits_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_tier, "Standard")
  sa_sapbits_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_replication_type, "LRS")
  sa_sapbits_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_kind, "StorageV2")
  sa_sapbits_enable_secure_transfer   = true
  sa_sapbits_arm_id                   = local.sa_sapbits_exists ? try(var.storage_account_sapbits.arm_id, "") : ""

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
  sa_tfstate_exists                   = try(var.storage_account_tfstate.is_existing, false)
  sa_tfstate_account_tier             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
  sa_tfstate_account_replication_type = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
  sa_tfstate_account_kind             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
  sa_tfstate_container_access_type    = "private"
  sa_tfstate_name                     = local.sa_tfstate_exists ? split("/", local.sa_tfstate_arm_id)[8] : lower(format("%s%stfstate%s", substr(local.environment, 0, 5), local.location_short, substr(random_id.post_fix.hex, 0, 4)))
  sa_tfstate_arm_id                   = local.sa_tfstate_exists ? try(var.storage_account_tfstate.arm_id, "") : ""
  sa_tfstate_enable_secure_transfer   = true
  sa_tfstate_delete_retention_policy  = 7

  sa_tfstate_container_exists = try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
  sa_tfstate_container_name   = try(var.storage_account_sapbits.tfstate_blob_container.name, "tfstate")
}

locals {
  rg_library_location      = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  storagecontainer_sapbits = ! local.sa_sapbits_blob_container_enable ? null : local.sa_sapbits_blob_container_name
  fileshare_sapbits_name   = local.sa_sapbits_file_share_enable ? local.sa_sapbits_file_share_name : null
}
