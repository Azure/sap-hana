/* 
  Description:
  Generate scripts to migrate tfstate from local to remote
*/

// Generate script to migrate tfstate of sap library from local to remote
resource "local_file" "output-saplibrary-script" {
    content = templatefile("${path.root}/saplibrary_tfstate_script.tmpl", {
    saplibrary-resource-group       =  module.sap_library.rgName
    tfstate-storage-account-name    =  module.sap_library.tfstate-storage-account-name
    saplibrary_terraform_tfstate_path    =  pathexpand("~/.config/saplibrary.terraform.tfstate")
    }
  )
  filename             = "../../run/sap_library/${terraform.workspace}/saplibrary_tfstate_script.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}

// Generate script to migrate tfstate of deployer from local to remote
resource "local_file" "output-deployer-script" {
    content = templatefile("${path.root}/deployer_tfstate_script.tmpl", {
    saplibrary-resource-group       =  module.sap_library.rgName
    tfstate-storage-account-name    =  module.sap_library.tfstate-storage-account-name
    deployer_terraform_tfstate_path      = pathexpand("~/.config/deployer.terraform.tfstate")
    }
  )
  filename             = "../../run/sap_deployer/${terraform.workspace}/deployer_tfstate_script.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}
