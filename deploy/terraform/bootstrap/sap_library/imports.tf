/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "local_deployer" {
  backend = "local"
  config = {
    path = "$../../LOCAL/${local.deployer_rg_name}/terraform.tfstate"
  }
}

data "azurerm_key_vault_secret" "subscription_id" {
  provider     = azurerm.deployer
  name         = "deployer-subscription-id"
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_id" {
  provider     = azurerm.deployer
  name         = "deployer-client-id"
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_secret" {
  provider     = azurerm.deployer
  name         = "deployer-client-secret"
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  provider     = azurerm.deployer
  name         = "deployer-tenant-id"
  key_vault_id = local.deployer_key_vault_arm_id
}
