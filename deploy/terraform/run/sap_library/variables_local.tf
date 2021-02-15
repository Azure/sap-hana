
variable "tfstate_resource_id" {
  description = "The resource id of tfstate storage account"
  default     = ""
}

locals {
  
  deployer_prefix         = module.sap_namegenerator.naming.prefix.DEPLOYER
  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name = try(var.deployer.resource_group_name, format("%s%s", local.deployer_prefix, module.sap_namegenerator.naming.resource_suffixes.deployer_rg))

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  deployer_key_vault_arm_id = try(var.key_vault.kv_spn_id, try(data.terraform_remote_state.deployer.outputs.deployer_kv_user_arm_id, ""))

  // Locate the tfstate storage account
  tfstate_resource_id          = try(var.tfstate_resource_id, "")
  saplib_subscription_id       = split("/", local.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", local.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", local.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate
  deployer_tfstate_key         = format("%s%s", local.deployer_rg_name, ".terraform.tfstate")

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
