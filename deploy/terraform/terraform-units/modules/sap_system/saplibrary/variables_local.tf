// TODO: consolidate shared mapping during naming modular project
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

// Imports from saplibrary tfstate
locals {
  // Get saplib remote tfstate info
  sapbits_config = try(var.software.storage_account_sapbits, {})

  // Get info required for naming convention
  environment    = lower(substr(try(var.infrastructure.environment, ""), 0, 5))
  region         = lower(try(var.infrastructure.region, ""))
  location_short = lower(try(var.region_mapping[local.region], "unkn"))

  // Default value follows naming convention
  saplib_resource_group_name   = try(local.sapbits_config.saplib_resource_group_name, "${local.environment}-${local.location_short}-sap_library")
  tfstate_storage_account_name = try(local.sapbits_config.tfstate_storage_account_name, "")
  tfstate_container_name       = try(local.sapbits_config.tfstate_container_name, "saplibrary")
  saplib_tfstate_key           = try(local.sapbits_config.saplib_tfstate_key, "${local.environment}-${local.location_short}-sap_library.terraform.tfstate")

}

locals {
  file_share_exists          = try(data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name, null) == null ? false : true
  blob_container_exists      = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits, null) == null ? false : true
  storagecontainer_sapsystem = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapsystem, null)
  sa_tfstate                 = try(data.terraform_remote_state.saplibrary.outputs.tfstate_storage_account, null)


  db_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") != "NONE"
  ]
  db_sid  = length(local.db_list) == 0 ? "" : try(local.db_list[0].instance.sid, local.db_list[0].platform == "HANA" ? "HN1" : "OR1")
  app_sid = try(var.application.enable_deployment, false) ? try(var.application.sid, "") : ""
  // SID decided by application SID if exists, otherwise, use database SID, none provided, default to SID
  sid = local.app_sid != "" ? local.app_sid : (local.db_sid != "" ? local.db_sid : "SID")

  /*
    TODO: currently data source azurerm_storage_share is not supported 
    https://github.com/terraform-providers/terraform-provider-azurerm/issues/4931
  */
  file_share_name = local.file_share_exists ? data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name : null
}
