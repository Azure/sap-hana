# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1) : 0
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 1 : 0) : 0
  name                = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[4]
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-app" {
  count                     = local.enable_deployment ? (signum((var.infrastructure.vnets.sap.subnet_app.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1))) : 0
  subnet_id                 = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}
