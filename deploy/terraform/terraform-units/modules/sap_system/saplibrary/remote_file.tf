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
  source                 = "${path.root}/${local.landscape_id}_${local.sid}.json"
}
