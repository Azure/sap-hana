/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "local_deployer" {
  backend = "local"
  config  = {
    path  = "${abspath(path.cwd)}/../../LOCAL/${local.deployer_rg_name}/terraform.tfstate"
  }
}

data "azurerm_key_vault_secret" "subscription_id" {
  provider     = azurerm.deployer
  name         = format("%s-subscription-id", local.environment)
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_id" {
  provider     = azurerm.deployer
  name         = format("%s-client-id", local.environment)
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_secret" {
  provider     = azurerm.deployer
  name         = format("%s-client-secret", local.environment)
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  provider     = azurerm.deployer
  name         = format("%s-tenant-id", local.environment)
  key_vault_id = local.deployer_key_vault_arm_id
}
