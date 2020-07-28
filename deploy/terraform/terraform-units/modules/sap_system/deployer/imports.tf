/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "deployer" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.deployer_config.deployer.resource_group_name
    storage_account_name = local.deployer_config.deployer.storage_account_name
    container_name       = local.deployer_config.deployer.container_name
    key                  = local.deployer_config.deployer.key
  }
}

// Import deployer management vnet
data "azurerm_virtual_network" "vnet-mgmt" {
  name                = data.terraform_remote_state.deployer.outputs.vnet-mgmt.name
  resource_group_name = data.terraform_remote_state.deployer.outputs.vnet-mgmt.resource_group_name
}

// Import deployer management subnet
data "azurerm_subnet" "subnet-mgmt" {
  name                 = data.terraform_remote_state.deployer.outputs.subnet-mgmt.name
  resource_group_name  = data.terraform_remote_state.deployer.outputs.subnet-mgmt.resource_group_name
  virtual_network_name = data.terraform_remote_state.deployer.outputs.subnet-mgmt.virtual_network_name
}

// Import deployer management nsg
data "azurerm_network_security_group" "nsg-mgmt" {
  name                = data.terraform_remote_state.deployer.outputs.nsg-mgmt.name
  resource_group_name = data.terraform_remote_state.deployer.outputs.nsg-mgmt.resource_group_name
}

// Import UAI
data "azurerm_user_assigned_identity" "deployer" {
  name                = data.terraform_remote_state.deployer.outputs.deployer-uai.name
  resource_group_name = data.terraform_remote_state.deployer.outputs.deployer-uai.resource_group_name
}
