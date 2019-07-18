##################################################################################################################
# RESOURCES
##################################################################################################################

# RESOURCE GROUP =================================================================================================

# Creates the resource group
resource "azurerm_resource_group" "rg" {
  count    = var.infrastructure.resource_group.is_existing ? 0 : 1
  name     = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  location = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
}

# VNETs ==========================================================================================================

# Creates the management VNET
resource "azurerm_virtual_network" "vnet-mgmt" {
  count               = var.infrastructure.vnets.management.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  address_space       = var.infrastructure.vnets.management.address_space == "" ? [var.infra_default.vnets.management.address_space] : [var.infrastructure.vnets.management.address_space]
}

# Creates the SAP VNET
resource "azurerm_virtual_network" "vnet-sap" {
  count               = var.infrastructure.vnets.sap.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  address_space       = var.infrastructure.vnets.sap.address_space == "" ? [var.infra_default.vnets.sap.address_space] : [var.infrastructure.vnets.sap.address_space]
}

# Imports existing management VNET data
data "azurerm_virtual_network" "vnet-mgmt" {
  count               = var.infrastructure.vnets.management.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name
  resource_group_name = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# Imports existing SAP VNET data
data "azurerm_virtual_network" "vnet-sap" {
  count               = var.infrastructure.vnets.sap.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  resource_group_name = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# SUBNETs ========================================================================================================

# Creates the management VNET's default subnet
resource "azurerm_subnet" "subnet-mgmt-default" {
  count                = var.infrastructure.vnets.management.subnet_default.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.management.subnet_default.name == "" ? var.infra_default.vnets.management.subnet_default.name : var.infrastructure.vnets.management.subnet_default.name
  resource_group_name  = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name = !var.infrastructure.vnets.management.is_existing ? azurerm_virtual_network.vnet-mgmt[0].name : var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name
  address_prefix       = var.infrastructure.vnets.management.subnet_default.prefix == "" ? var.infra_default.vnets.management.subnet_default.prefix : var.infrastructure.vnets.management.subnet_default.prefix
}

# Creates the SAP VNET's admin subnet
resource "azurerm_subnet" "subnet-sap-admin" {
  count                = var.infrastructure.vnets.sap.subnet_admin.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_admin.name == "" ? var.infra_default.vnets.sap.subnet_admin.name : var.infrastructure.vnets.sap.subnet_admin.name
  resource_group_name  = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name = !var.infrastructure.vnets.sap.is_existing ? azurerm_virtual_network.vnet-sap[0].name : var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  address_prefix       = var.infrastructure.vnets.sap.subnet_admin.prefix == "" ? var.infra_default.vnets.sap.subnet_admin.prefix : var.infrastructure.vnets.sap.subnet_admin.prefix
}

# Creates the SAP VNET's client subnet
resource "azurerm_subnet" "subnet-sap-client" {
  count                = var.infrastructure.vnets.sap.subnet_client.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_client.name == "" ? var.infra_default.vnets.sap.subnet_client.name : var.infrastructure.vnets.sap.subnet_client.name
  resource_group_name  = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name = !var.infrastructure.vnets.sap.is_existing ? azurerm_virtual_network.vnet-sap[0].name : var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  address_prefix       = var.infrastructure.vnets.sap.subnet_client.prefix == "" ? var.infra_default.vnets.sap.subnet_client.prefix : var.infrastructure.vnets.sap.subnet_client.prefix
}

# Creates the SAP VNET's app subnet
resource "azurerm_subnet" "subnet-sap-app" {
  count                = var.infrastructure.vnets.sap.subnet_app.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_app.name == "" ? var.infra_default.vnets.sap.subnet_app.name : var.infrastructure.vnets.sap.subnet_app.name
  resource_group_name  = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name = !var.infrastructure.vnets.sap.is_existing ? azurerm_virtual_network.vnet-sap[0].name : var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  address_prefix       = var.infrastructure.vnets.sap.subnet_app.prefix == "" ? var.infra_default.vnets.sap.subnet_app.prefix : var.infrastructure.vnets.sap.subnet_app.prefix
}

# NSGs ===========================================================================================================

# Creates management default subnet nsg
resource "azurerm_network_security_group" "nsg-mgmt-default" {
  count               = var.infrastructure.vnets.management.subnet_default.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.management.subnet_default.nsg.name == "" ? var.infra_default.vnets.management.subnet_default.nsg.name : var.infrastructure.vnets.management.subnet_default.nsg.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# Creates SAP admin subnet nsg
resource "azurerm_network_security_group" "nsg-sap-admin" {
  count               = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_admin.nsg.name == "" ? var.infra_default.vnets.sap.subnet_admin.nsg.name : var.infrastructure.vnets.sap.subnet_admin.nsg.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# Creates SAP client subnet nsg
resource "azurerm_network_security_group" "nsg-sap-client" {
  count               = var.infrastructure.vnets.sap.subnet_client.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_client.nsg.name == "" ? var.infra_default.vnets.sap.subnet_client.nsg.name : var.infrastructure.vnets.sap.subnet_client.nsg.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-sap-app" {
  count               = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name == "" ? var.infra_default.vnets.sap.subnet_app.nsg.name : var.infrastructure.vnets.sap.subnet_app.nsg.name
  location            = var.infrastructure.region == "" ? var.infra_default.region : var.infrastructure.region
  resource_group_name = !var.infrastructure.resource_group.is_existing ? azurerm_resource_group.rg[0].name : var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
}

# VNET PEERINGs ==================================================================================================

# Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering-mgmt-sap" {
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = "${var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name}-${var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name}"
  resource_group_name          = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name         = !var.infrastructure.vnets.management.is_existing ? azurerm_virtual_network.vnet-mgmt[0].name : var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name
  remote_virtual_network_id    = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
  allow_virtual_network_access = true
}

# Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering-sap-mgmt" {
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = "${var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name}-${var.infrastructure.vnets.management.name == "" ? var.infra_default.vnets.management.name : var.infrastructure.vnets.management.name}"
  resource_group_name          = var.infrastructure.resource_group.name == "" ? var.infra_default.resource_group : var.infrastructure.resource_group.name
  virtual_network_name         = !var.infrastructure.vnets.sap.is_existing ? azurerm_virtual_network.vnet-sap[0].name : var.infrastructure.vnets.sap.name == "" ? var.infra_default.vnets.sap.name : var.infrastructure.vnets.sap.name
  remote_virtual_network_id    = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-mgmt[0].id : azurerm_virtual_network.vnet-mgmt[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
