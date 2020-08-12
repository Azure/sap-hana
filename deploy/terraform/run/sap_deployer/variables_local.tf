locals {
  // Import deployer info from config
  config_path     = pathexpand("~/.config/sa_config.json")
  deployer_config = jsondecode(file(local.config_path))

  storagecontainer_deployer_name = local.deployer_config.deployer.container_name
  sa_tfstate_name                = local.deployer_config.deployer.storage_account_name
}
