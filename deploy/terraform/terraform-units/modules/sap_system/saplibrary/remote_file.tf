/*
  Description:
  Upload json files to stroage account 
*/

// Upload sapsystem.json to json container
resource "azurerm_storage_blob" "sapsystem_json" {
  name                   = "${local.landscape_id}/${local.sid}/${local.landscape_id}_${local.sid}.json"
  storage_account_name   = local.sa_tfstate.name
  storage_container_name = local.storagecontainer_sapsystem.name
  type                   = "Block"
  // TODO: azure is working on enable content_md5. It will force a new deployment if the value for content_md5 is changed, 
  // When this feature is launched, we can choose to use "source" combined with content_md5
  // https://github.com/terraform-providers/terraform-provider-azurerm/pull/7786
  source_content         = file("${path.root}/${local.landscape_id}_${local.sid}.json")
}
