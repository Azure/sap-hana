/*
  Description:
  Upload json files to storage account 
*/

// Upload deployer.json to deployer container
resource "azurerm_storage_blob" "deployer_json" {
  name                   = "${local.storagecontainer_deployer_name}.json"
  storage_account_name   = local.sa_tfstate_name
  storage_container_name = local.storagecontainer_deployer_name
  type                   = "Block"
  // TODO: azure is working on enable content_md5. It will force a new deployment if the value for content_md5 is changed. 
  // When this feature is launched, we can choose to use "source" combined with content_md5
  // https://github.com/terraform-providers/terraform-provider-azurerm/pull/7786
  source_content         = file(pathexpand("~/.config/${local.storagecontainer_deployer_name}.json"))
}
