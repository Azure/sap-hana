/*
    Description:
      Import sapbits resources
*/

data "terraform_remote_state" "saplibrary" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.saplib_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = local.saplib_tfstate_key
  }
}

// Import SA for sap bits
data "azurerm_storage_account" "saplibrary" {
  name                = data.terraform_remote_state.saplibrary.outputs.sapbits_storage_account_name
  resource_group_name = data.terraform_remote_state.saplibrary.outputs.sapbits_sa_resource_group_name
}

// Import storage container for sap bits if exists
data "azurerm_storage_container" "storagecontainer-sapbits" {
  count                = local.blob_container_exists ? 1 : 0
  name                 = data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits_name
  storage_account_name = data.terraform_remote_state.saplibrary.outputs.sapbits_storage_account_name
}
