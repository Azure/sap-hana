/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "saplibrary" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.deployer_config.saplibrary.resource_group_name
    storage_account_name = local.deployer_config.saplibrary.storage_account_name
    container_name       = local.deployer_config.saplibrary.container_name
    key                  = local.deployer_config.saplibrary.key
  }
}

// Import SA for sap bits
data "azurerm_storage_account" "saplibrary" {
  name                = data.terraform_remote_state.saplibrary.outputs.sapbits_storage_account.name
  resource_group_name = data.terraform_remote_state.saplibrary.outputs.sapbits_storage_account.resource_group_name
}

// Import storage container for sap bits if exists
data "azurerm_storage_container" "storagecontainer-sapbits" {
  count                = local.blob_container_exists ? 1 : 0
  name                 = data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits.name
  storage_account_name = data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits.storage_account_name
}
