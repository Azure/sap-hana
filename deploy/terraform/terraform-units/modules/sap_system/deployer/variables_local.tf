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

// Imports from tfstate
locals {
  // Get deployer remote tfstate info
  deployer_config = try(var.infrastructure.vnets.management, {})

  // Get info required for naming convention
  environment    = lower(try(var.infrastructure.environment, ""))
  region         = lower(try(var.infrastructure.region, ""))
  location_short = lower(try(var.region_mapping[local.region], "unkn"))

  // Default value follows naming convention
  saplib_resource_group_name   = try(local.deployer_config.saplib_resource_group_name, "${local.environment}-${local.location_short}-sap_library")
  tfstate_storage_account_name = try(local.deployer_config.tfstate_storage_account_name, "")
  tfstate_container_name       = "saplibrary"
  deployer_tfstate_key         = try(local.deployer_config.deployer_tfstate_key, "${local.environment}-${local.location_short}-deployer-infrastructure.terraform.tfstate")
}
