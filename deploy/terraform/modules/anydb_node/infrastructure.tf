
# Creates db subnet of SAP VNET
resource "azurerm_subnet" "subnet-anydb" {
  count                = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_db.is_existing ? 0 : 1) : 0
  name                 = var.infrastructure.vnets.sap.subnet_db.name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [var.infrastructure.vnets.sap.subnet_db.prefix]
}

# Imports data of existing any-db subnet
data "azurerm_subnet" "subnet-anydb" {
  count                = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_db.is_existing ? 1 : 0) : 0
  name                 = split("/", var.infrastructure.vnets.sap.subnet_db.arm_id)[10]
  resource_group_name  = split("/", var.infrastructure.vnets.sap.subnet_db.arm_id)[4]
  virtual_network_name = split("/", var.infrastructure.vnets.sap.subnet_db.arm_id)[8]
}

# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "nsg-anydb" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 0 : 1) : 0
  name                = var.infrastructure.vnets.sap.subnet_db.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.vnet-sap[0].resource_group_name
}

# Imports the SAP db subnet nsg data
data "azurerm_network_security_group" "nsg-anydb" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 1 : 0) : 0
  name                = split("/", var.infrastructure.vnets.sap.subnet_db.nsg.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.sap.subnet_db.nsg.arm_id)[4]
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-db" {
  count                     = local.enable_deployment ? signum((var.infrastructure.vnets.sap.subnet_db.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 0 : 1)) : 0
  subnet_id                 = var.infrastructure.vnets.sap.subnet_db.is_existing ? data.azurerm_subnet.subnet-anydb[0].id : azurerm_subnet.subnet-anydb[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? data.azurerm_network_security_group.nsg-anydb[0].id : azurerm_network_security_group.nsg-anydb[0].id
}
