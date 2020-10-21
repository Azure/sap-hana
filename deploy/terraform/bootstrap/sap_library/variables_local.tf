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
  // Sap library's environment
  environment = upper(try(var.infrastructure.environment, ""))

  // Derive resource group name for deployer
  deployer                = try(var.deployer, {})
  deployer_environment    = try(local.deployer.environment, "")
  deployer_location_short = try(var.region_mapping[local.deployer.region], "unkn")
  deployer_vnet           = try(local.deployer.vnet, "")
  deployer_prefix         = upper(format("%s-%s-%s", local.deployer_environment, local.deployer_location_short, substr(local.deployer_vnet, 0, 7)))
  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name = try(local.deployer.resource_group_name, format("%s-INFRASTRUCTURE", local.deployer_prefix))

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  deployer_key_vault_arm_id = try(data.terraform_remote_state.deployer.outputs.deployer_kv_user_arm_id, "")

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = data.azurerm_key_vault_secret.client_id.value,
    client_secret   = data.azurerm_key_vault_secret.client_secret.value,
    tenant_id       = data.azurerm_key_vault_secret.tenant_id.value,
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    client_id       = local.spn.client_id,
    client_secret   = local.spn.client_secret,
    tenant_id       = local.spn.tenant_id,
    object_id       = data.azuread_service_principal.sp.id
  }

}
