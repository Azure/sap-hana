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
  // TODO: azure is working on enable content_md5. It will force a new deployment if the value for content_md5 is changed, 
  // When this feature is launched, we can choose to use "source" combined with content_md5
  // https://github.com/terraform-providers/terraform-provider-azurerm/pull/7786
  source_content         = file(pathexpand("~/.config/${local.storagecontainer_deployer.name}.json"))
}

// Upload saplibrary.json to saplibrary container
resource "azurerm_storage_blob" "saplibrary_json" {
  name                   = "${local.storagecontainer_saplibrary.name}.json"
  storage_account_name   = local.sa_tfstate.name
  storage_container_name = local.storagecontainer_saplibrary.name
  type                   = "Block"
  // TODO: azure is working on enable content_md5. It will force a new deployment if the value for content_md5 is changed, 
  // When this feature is launched, we can choose to use "source" combined with content_md5
  // https://github.com/terraform-providers/terraform-provider-azurerm/pull/7786
  source_content         = file("${path.root}/${local.storagecontainer_saplibrary.name}.json")
}
