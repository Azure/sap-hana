/* 
  Description:
  Generate a script to migrate tfstate of storage accounts from local to remote
*/
resource "local_file" "output-script" {
    content = templatefile("${path.root}/tfstate_scripts.tmpl", {
    saplibrary-resource-group       =  module.sap_library.rgName
    tfstate-storage-account-name    =  module.sap_library.tfstate-storage-account-name
    }
  )
  filename             = "${terraform.workspace}/tfstate_scripts.sh"
  file_permission      = "0660"
  directory_permission = "0770"
}
