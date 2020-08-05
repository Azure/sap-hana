/*
  Description:
  Upload json files to stroage account 
*/

// Upload deployer.json to deployer container
resource "azurerm_storage_blob" "deployer_json" {
  name                   = "${local.storagecontainer_deployer.name}.json"
  storage_account_name   = local.sa_tfstate.name
  storage_container_name = local.storagecontainer_deployer.name
  type                   = "Block"
  source                 = pathexpand("~/.config/${local.storagecontainer_deployer.name}.json")
}

// Upload saplibrary.json to saplibrary container
resource "azurerm_storage_blob" "saplibrary_json" {
  name                   = "${local.storagecontainer_saplibrary.name}.json"
  storage_account_name   = local.sa_tfstate.name
  storage_container_name = local.storagecontainer_saplibrary.name
  type                   = "Block"
  source                 = "${path.root}/${local.storagecontainer_saplibrary.name}.json"
}
