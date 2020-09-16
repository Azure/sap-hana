output "import_deployer" {
  value = data.terraform_remote_state.deployer.outputs.deployer
}

output "vnet-mgmt" {
  value = data.azurerm_virtual_network.vnet-mgmt
}

output "subnet-mgmt" {
  value = data.azurerm_subnet.subnet-mgmt
}

output "nsg-mgmt" {
  value = data.azurerm_network_security_group.nsg-mgmt
}

output "deployer-uai" {
  value = data.azurerm_user_assigned_identity.deployer
}

output "deployer_user" {
  value = data.terraform_remote_state.deployer.outputs.deployer_user
}
