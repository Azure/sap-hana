/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "deployer" {
  backend = "local"
  config = {
    path = "${abspath(path.cwd)}/../../LOCAL/${local.deployer_rg_name}/terraform.tfstate"
  }
}

data "azurerm_key_vault_secret" "subscription_id" {
  provider     = azurerm.deployer
  name         = format("%s-subscription-id", upper(var.infrastructure.environment))
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_id" {
  provider     = azurerm.deployer
  name         = format("%s-client-id", upper(var.infrastructure.environment))
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_secret" {
  provider     = azurerm.deployer
  name         = format("%s-client-secret", upper(var.infrastructure.environment))
  key_vault_id = local.deployer_key_vault_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  provider     = azurerm.deployer
  name         = format("%s-tenant-id", upper(var.infrastructure.environment))
  key_vault_id = local.deployer_key_vault_arm_id
}

// Import current service principal
data "azuread_service_principal" "sp" {
  application_id = local.spn.client_id
}
