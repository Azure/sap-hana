# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-app" {
  count                = var.infrastructure.vnets.sap.subnet_app.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_app.name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [var.infrastructure.vnets.sap.subnet_app.prefix]
}

# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet-sap-app" {
  count                = var.infrastructure.vnets.sap.subnet_app.is_existing ? 1 : 0
  name                 = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[10]
  resource_group_name  = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[4]
  virtual_network_name = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[8]
}

# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-app" {
  count               = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.vnet-sap[0].resource_group_name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-app" {
  count               = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 1 : 0
  name                = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[4]
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-app" {
  count                     = signum((var.infrastructure.vnets.sap.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1))
  subnet_id                 = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}
