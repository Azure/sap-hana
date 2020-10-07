// If the local terraform tfstate contains the arm id of deployer's KeyVault, it will be used. Otherwise, the information will be fetched from remote tfstate.
locals {
  environment                  = try(var.infrastructure.environment, "")
  deployer                     = try(var.deployer, "")
  deployer_key_vault_arm_id    = try(data.terraform_remote_state.remote_deployer.outputs.deployer_kv_user_arm_id, "")
  saplib_resource_group_name   = try(local.deployer.saplib_resource_group_name, "")
  tfstate_storage_account_name = try(local.deployer.tfstate_storage_account_name, "")
  tfstate_container_name       = "tfstate"
  deployer_tfstate_key         = try(local.deployer.deployer_tfstate_key, "")

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = data.azurerm_key_vault_secret.client_id.value,
    client_secret   = data.azurerm_key_vault_secret.client_secret.value,
    tenant_id       = data.azurerm_key_vault_secret.tenant_id.value,
  }

}
