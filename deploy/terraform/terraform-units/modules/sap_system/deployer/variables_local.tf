// Imports from tfstate
locals {
  // Import deployer config
  config_path     = "../../bootstrap/.deploy/sa_config.json"
  deployer_config = jsondecode(file(local.config_path))
}
