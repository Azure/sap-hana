/*
  Description:
  Upload json file to storage account 
*/

// Upload saplibrary.json to saplibrary container
resource "azurerm_storage_blob" "saplibrary_json" {
  name                   = "${module.sap_library.storagecontainer_saplibrary.name}.json"
  storage_account_name   = module.sap_library.tfstate_storage_account.name
  storage_container_name = module.sap_library.storagecontainer_saplibrary.name
  type                   = "Block"
  // TODO: azure is working on enable content_md5. It will force a new deployment if the value for content_md5 is changed.
  // When this feature is launched, we can choose to use "source" combined with content_md5
  // https://github.com/terraform-providers/terraform-provider-azurerm/pull/7786
  source_content         = file("${path.root}/${module.sap_library.storagecontainer_saplibrary.name}.json")
}
