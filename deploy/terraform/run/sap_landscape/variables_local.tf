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
}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
}

locals {

  // The environment of sap landscape and sap system
  environment = upper(try(var.infrastructure.environment, ""))

  vnet_sap_name = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, "sap")
  vnet_nr_parts = length(split("-", local.vnet_sap_name))
  // Default naming of vnet has multiple parts. Taking the second-last part as the name 
  vnet_sap_name_part = try(substr(upper(local.vnet_sap_name), -5, 5), "") == "-VNET" ? substr(split("-", local.vnet_sap_name)[(local.vnet_nr_parts - 2)], 0, 7) : local.vnet_sap_name

  # Options
  enable_secure_transfer = try(var.options.enable_secure_transfer, true)
  ansible_execution      = try(var.options.ansible_execution, false)
  enable_prometheus      = try(var.options.enable_prometheus, true)

  # Update options with defaults
  options = merge(var.options, {
    enable_secure_transfer = local.enable_secure_transfer,
    ansible_execution      = local.ansible_execution,
    enable_prometheus      = local.enable_prometheus
  })

  // SAP vnet
  var_infra       = try(var.infrastructure, {})
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false

  // iSCSI
  var_iscsi   = try(local.var_infra.iscsi, {})
  iscsi_count = try(local.var_iscsi.iscsi_count, 0)

  // Locate the tfstate storage account
  tfstate_resource_id          = try(var.tfstate_resource_id, "")
  saplib_subscription_id       = split("/", local.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", local.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", local.tfstate_resource_id)[8]
  tfstate_container_name       = "tfstate"
  deployer_tfstate_key         = try(var.deployer_tfstate_key, "")

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
