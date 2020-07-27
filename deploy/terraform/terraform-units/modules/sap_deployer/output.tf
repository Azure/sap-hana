/*
Description:

  Output from sap_deployer module.
*/

// Unique ID for deployer
output "deployer-id" {
  value = random_id.deployer
}

// Details of management vnet that is deployed/imported
output "vnet-mgmt" {
  value = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-mgmt[0] : azurerm_virtual_network.vnet-mgmt[0]
}

// Details of the user assigned identity for deployer(s)
output "deployer-uai" {
  value = azurerm_user_assigned_identity.deployer
}

