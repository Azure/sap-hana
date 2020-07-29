/* 
  Description:
  Generate json for storage account config
*/
resource "local_file" "sa-config" {
  content = templatefile("${path.root}/sa_config.tmpl", {
    saplibrary-resource-group    = module.sap_library.rgName
    tfstate-storage-account-name = module.sap_library.tfstate-storage-account-name
    }
  )
  filename        = pathexpand("~/.config/sa_config.json")
  file_permission = "0660"
}
