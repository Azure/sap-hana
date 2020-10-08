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
  // Derive resource group name for saplibrary
  var_infra      = try(var.infrastructure, {})
  region         = try(local.var_infra.region, "")
  environment    = upper(try(var.infrastructure.environment, ""))
  location_short = try(var.region_mapping[local.region], "unkn")
  prefix         = upper(format("%s-%s", local.environment, local.location_short))
  var_rg         = try(local.var_infra.resource_group, {})
  rg_exists      = try(local.var_rg.is_existing, false)
  rg_arm_id      = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
  rg_name        = local.rg_exists ? "" : try(local.var_rg.name, format("%s-SAP_LIBRARY", local.prefix))

  // Derive resource group name for deployer
  deployer                = try(var.deployer, {})
  deployer_environment    = try(local.deployer.environment, "")
  deployer_location_short = try(var.region_mapping[local.deployer.region], "unkn")
  deployer_vnet           = try(local.deployer.vnet, "")
  deployer_prefix         = upper(format("%s-%s-%s", local.deployer_environment, local.deployer_location_short, substr(local.deployer_vnet, 0, 7)))
  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name = try(local.deployer.resource_group_name, format("%s-INFRASTRUCTURE", local.deployer_prefix))

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  deployer_key_vault_arm_id = try(data.terraform_remote_state.remote_deployer.outputs.deployer_kv_user_arm_id, "")

  saplib_resource_group_name   = local.rg_name
  tfstate_storage_account_name = local.deployer.tfstate_storage_account_name
  tfstate_container_name       = "tfstate"
  deployer_tfstate_key         = format("%s%s", local.deployer_rg_name, ".terraform.tfstate")

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = data.azurerm_key_vault_secret.client_id.value,
    client_secret   = data.azurerm_key_vault_secret.client_secret.value,
    tenant_id       = data.azurerm_key_vault_secret.tenant_id.value,
  }

}
