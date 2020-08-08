// Imports from saplibrary tfstate
locals {
  // Import saplibrary info from config
  config_path     = pathexpand("~/.config/sa_config.json")
  deployer_config = jsondecode(file(local.config_path))
}

locals {
  file_share_exists          = try(data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name, null) == null ? false : true
  blob_container_exists      = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits, null) == null ? false : true
  storagecontainer_sapsystem = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapsystem, null)
  sa_tfstate                 = try(data.terraform_remote_state.saplibrary.outputs.tfstate_storage_account, null)


  db_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") != "NONE"
  ]
  db_sid  = length(local.db_list) == 0 ? "" : try(local.db_list[0].instance.sid, local.db_list[0].platform == "HANA" ? "HN1" : "OR1")
  app_sid = try(var.application.enable_deployment, false) ? try(var.application.sid, "") : ""
  // SID decided by application SID if exists, otherwise, use database SID, none provided, default to SID
  sid          = local.app_sid != "" ? local.app_sid : (local.db_sid != "" ? local.db_sid : "SID")
  landscape_id = try(var.infrastructure.landscape, "TEST")

  /*
    TODO: currently data source azurerm_storage_share is not supported 
    https://github.com/terraform-providers/terraform-provider-azurerm/issues/4931
  */
  file_share_name = local.file_share_exists ? data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name : null
}
