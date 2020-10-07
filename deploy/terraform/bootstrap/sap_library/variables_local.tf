// If the local terraform tfstate contains the arm id of deployer's KeyVault, it will be used. Otherwise, the information will be fetched from remote tfstate.
locals {

  deployer                  = try(var.deployer, "")
  environment               = try(var.infrastructure.environment, "")
  deployer_rg_name          = try(local.deployer.resource_group.name, "")
  deployer_key_vault_arm_id = try(data.terraform_remote_state.local_deployer.outputs.deployer_kv_user_arm_id, "")

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = data.azurerm_key_vault_secret.client_id.value,
    client_secret   = data.azurerm_key_vault_secret.client_secret.value,
    tenant_id       = data.azurerm_key_vault_secret.tenant_id.value,
  }

}
