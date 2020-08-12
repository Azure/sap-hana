/* 
  Description:
  Generate json for storage account config
*/
resource "local_file" "sa_config" {
  content = templatefile("${path.module}/sa_config.tmpl", {
    saplibrary_resource_group_name   = local.sa_tfstate.resource_group_name
    tfstate_storage_account_name     = local.sa_tfstate.name
    storagecontainer_saplibrary_name = local.storagecontainer_saplibrary.name
    storagecontainer_deployer_name   = local.storagecontainer_deployer.name
    saplibrary_tfstate_name          = "${local.storagecontainer_saplibrary.name}.terraform.tfstate"
    deployer_tfstate_name            = "${local.storagecontainer_deployer.name}.terraform.tfstate"
    }
  )
  filename        = pathexpand("~/.config/sa_config.json")
  file_permission = "0660"
}
