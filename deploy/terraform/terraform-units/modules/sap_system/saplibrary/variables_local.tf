// Input arguments 
variable naming {
  description = "Defines the names for the resources"
}

// Imports from saplibrary tfstate
locals {

  resource_suffixes = var.naming.resource_suffixes
  // Get saplib remote tfstate info
  sapbits_config = try(var.software.storage_account_sapbits, {})

  environment = lower(substr(try(var.infrastructure.environment, ""), 0, 5))

  // Default value follows naming convention

  saplib_resource_group_name   = try(local.sapbits_config.saplib_resource_group_name, format("%s%s", var.naming.prefix.LIBRARY, local.resource_suffixes.library-rg))
  tfstate_storage_account_name = try(local.sapbits_config.tfstate_storage_account_name, "")
  tfstate_container_name       = try(local.sapbits_config.tfstate_container_name, "tfstate")
  saplib_tfstate_key           = try(local.sapbits_config.saplib_tfstate_key, format("%s%s", var.naming.prefix.LIBRARY, local.resource_suffixes.library-state))

}

locals {
  file_share_exists          = try(data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name, null) == null ? false : true
  blob_container_exists      = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits_name, null) == null ? false : true
  storagecontainer_sapsystem = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapsystem, null)
  sa_tfstate                 = try(data.terraform_remote_state.saplibrary.outputs.tfstate_storage_account, null)


  db_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") != "NONE"
  ]
  db_sid  = length(local.db_list) == 0 ? "" : try(local.db_list[0].instance.sid, local.db_list[0].platform == "HANA" ? "HN1" : "OR1")
  app_sid = try(var.application.enable_deployment, false) ? try(var.application.sid, "") : ""
  // SID decided by application SID if exists, otherwise, use database SID, none provided, default to SID
  sid = local.app_sid != "" ? local.app_sid : (local.db_sid != "" ? local.db_sid : "SID")

  /*
    TODO: currently data source azurerm_storage_share is not supported 
    https://github.com/terraform-providers/terraform-provider-azurerm/issues/4931
  */
  file_share_name = local.file_share_exists ? data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name : null
}
