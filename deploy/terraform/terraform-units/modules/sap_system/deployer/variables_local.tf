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

  // Locate the tfstate storage account
  tfstate_resource_id          = try(local.deployer_config.tfstate_resource_id, "")
  saplib_subscription_id       = split("/", local.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", local.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", local.tfstate_resource_id)[8]
  tfstate_container_name       = "tfstate"
  deployer_tfstate_key         = try(local.deployer_config.deployer_tfstate_key, "${local.environment}-${local.location_short}-deployer-infrastructure.terraform.tfstate")
}
