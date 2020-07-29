// Imports from saplibrary tfstate
locals {
  // Import saplibrary info from config
  config_path     = pathexpand("~/.config/sa_config.json")
  deployer_config = jsondecode(file(local.config_path))
}

locals {
  file_share_exists     = try(data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name, null) == null ? false : true
  blob_container_exists = try(data.terraform_remote_state.saplibrary.outputs.storagecontainer_sapbits, null) == null ? false : true

  /*
    TODO: currently data source azurerm_storage_share is not supported 
    https://github.com/terraform-providers/terraform-provider-azurerm/issues/4931
  */
  file_share_name = local.file_share_exists ? data.terraform_remote_state.saplibrary.outputs.fileshare_sapbits_name : null
}
