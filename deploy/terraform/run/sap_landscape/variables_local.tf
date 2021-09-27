variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "v2"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "HANA Database"
}

variable "tfstate_resource_id" {
  description = "Resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""

}

variable "use_ANF" {
  description = "Boolean flag indicating if ANF will be used"
  default     = false
}

variable "ANF_account_arm_id" {
  description = "The resource identifier (if any) for the NetApp account"
  default     = ""
}

variable "ANF_account_name" {
  description = "The NetApp account name (if any)"
  default     = ""
}

variable "ANF_service_level" {
  description = "The NetApp Service Level"
  default     = "Standard"
}

variable "ANF_pool_size" {
  description = "The NetApp Pool size"
  default     = 4
}



locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))

  // The environment of sap landscape and sap system
  environment = upper(local.infrastructure.environment)

  vnet_logical_name = local.infrastructure.vnets.sap.name

  // SAP vnet
  var_infra       = try(local.infrastructure, {})
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false

  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = try(local.key_vault.kv_spn_id, try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, ""))

  deployer_subscription_id = length(local.spn_key_vault_arm_id) > 0 ? split("/", local.spn_key_vault_arm_id)[2] : ""


  #Provide the ability to deploye without SPN (DevOps scenario)
  use_spn = !try(var.options.nospn, false)

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = local.use_spn ? try(data.azurerm_key_vault_secret.client_id[0].value, null) : null,
    client_secret   = local.use_spn ? try(data.azurerm_key_vault_secret.client_secret[0].value, null) : null,
    tenant_id       = local.use_spn ? try(data.azurerm_key_vault_secret.tenant_id[0].value, null) : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = local.use_spn ? try(data.azuread_service_principal.sp[0].id, null) : null
  }

  account = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }

  ANF_settings = {
    use           = var.use_ANF
    name          = var.ANF_account_name
    arm_id        = var.ANF_account_arm_id
    service_level = var.ANF_service_level
    size_in_tb    = var.ANF_pool_size

  }
}
