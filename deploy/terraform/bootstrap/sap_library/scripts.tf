/* 
  Description:
  Generate scripts to migrate tfstate files from local to remote
*/

// Generate script to migrate tfstate of sap library from local to remote
resource "local_file" "output_saplibrary_script" {
  content = templatefile("${path.root}/saplibrary_tfstate_script.tmpl", {
    saplibrary_resource_group_name    = module.sap_library.tfstate_storage_account.resource_group_name
    tfstate_storage_account_name      = module.sap_library.tfstate_storage_account.name
    storagecontainer_saplibrary_name  = module.sap_library.storagecontainer_saplibrary.name
    saplibrary_tfstate_name           = "${module.sap_library.storagecontainer_saplibrary.name}.terraform.tfstate"
    saplibrary_terraform_tfstate_path = pathexpand("~/.config/${module.sap_library.storagecontainer_saplibrary.name}.terraform.tfstate")
    }
  )
  filename             = "../../run/sap_library/${terraform.workspace}/saplibrary_tfstate_script.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}

// Generate script to migrate tfstate of deployer from local to remote
resource "local_file" "output_deployer_script" {
  content = templatefile("${path.root}/deployer_tfstate_script.tmpl", {
    saplibrary_resource_group_name  = module.sap_library.tfstate_storage_account.resource_group_name
    tfstate_storage_account_name    = module.sap_library.tfstate_storage_account.name
    storagecontainer_deployer_name  = module.sap_library.storagecontainer_deployer.name
    deployer_tfstate_name           = "${module.sap_library.storagecontainer_deployer.name}.terraform.tfstate"
    deployer_terraform_tfstate_path = pathexpand("~/.config/${module.sap_library.storagecontainer_deployer.name}.terraform.tfstate")
    }
  )
  filename             = "../../run/sap_deployer/${terraform.workspace}/deployer_tfstate_script.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}
