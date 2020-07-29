// Imports from tfstate
locals {
  // Import deployer config
  config_path     = pathexpand("~/.config/sa_config.json")
  deployer_config = jsondecode(file(local.config_path))
}
