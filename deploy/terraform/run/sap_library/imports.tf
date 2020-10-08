/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "remote_deployer" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.saplib_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = local.deployer_tfstate_key
    use_msi              = true
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
