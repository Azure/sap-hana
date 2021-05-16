
variable "tfstate_resource_id" {
  description = "The resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}


locals {
  
  version_label   = trimspace(file("${path.module}/../../../configs/version.txt"))
  deployer_prefix = module.sap_namegenerator.naming.prefix.DEPLOYER
  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name = try(var.deployer.resource_group_name, format("%s%s", local.deployer_prefix, module.sap_namegenerator.naming.resource_suffixes.deployer_rg))

  use_deployer = try(var.deployer.use,false)

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = try(var.key_vault.kv_spn_id, try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, ""))

  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate
  deployer_tfstate_key         = length(var.deployer_tfstate_key) > 0 ? var.deployer_tfstate_key : format("%s%s", local.deployer_rg_name, ".terraform.tfstate")

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
