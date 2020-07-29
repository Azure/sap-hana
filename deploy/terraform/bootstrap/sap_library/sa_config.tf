/* 
  Description:
  Generate json for storage account config
*/
resource "local_file" "sa_config" {
  content = templatefile("${path.root}/sa_config.tmpl", {
    saplibrary_resource_group_name   = module.sap_library.tfstate_storage_account.resource_group_name
    tfstate_storage_account_name     = module.sap_library.tfstate_storage_account.name
    storagecontainer_saplibrary_name = module.sap_library.storagecontainer_saplibrary.name
    storagecontainer_deployer_name   = module.sap_library.storagecontainer_deployer.name
    saplibrary_tfstate_name          = "${module.sap_library.storagecontainer_saplibrary.name}.terraform.tfstate"
    deployer_tfstate_name            = "${module.sap_library.storagecontainer_deployer.name}.terraform.tfstate"
    }
  )
  filename        = pathexpand("~/.config/sa_config.json")
  file_permission = "0660"
}
