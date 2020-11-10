/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/

data "terraform_remote_state" "deployer" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.saplib_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = local.deployer_tfstate_key
    subscription_id      = local.saplib_subscription_id
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

// Import current service principal
data "azuread_service_principal" "sp" {
  application_id = local.spn.client_id
}
