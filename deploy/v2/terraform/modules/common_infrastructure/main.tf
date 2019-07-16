# Creates the resource group
resource "azurerm_resource_group" "rg" {
  count    = var.resource_group_existing ? 0 : 1
  name     = var.resource_group_name
  location = var.region
}

# Creates the management vnet 
resource "azurerm_virtual_network" "mgmt-vnet" {
  count               = var.mgmt_vnet_existing ? 0 : 1
  name                = var.mgmt_vnet_name
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
  address_space       = [var.mgmt_vnet_address_space]
}

# Creates the sap vnet
resource "azurerm_virtual_network" "sap-vnet" {
  count               = var.sap_vnet_existing ? 0 : 1
  name                = var.sap_vnet_name
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
  address_space       = [var.sap_vnet_address_space]
}

# Creates the management default subnet
resource "azurerm_subnet" "mgmt-default-subnet" {
  count                = var.mgmt_default_subnet_existing ? 0 : 1
  name                 = var.mgmt_default_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.mgmt_vnet_existing ? var.mgmt_vnet_name : azurerm_virtual_network.mgmt-vnet[0].name
  address_prefix       = var.mgmt_default_subnet_prefix
}

# Creates the sap admin subnet
resource "azurerm_subnet" "sap-admin-subnet" {
  count                = var.sap_admin_subnet_existing ? 0 : 1
  name                 = var.sap_admin_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.sap_vnet_existing ? var.sap_vnet_name : azurerm_virtual_network.sap-vnet[0].name
  address_prefix       = var.sap_admin_subnet_prefix
}

# Creates the sap client subnet
resource "azurerm_subnet" "sap-client-subnet" {
  count                = var.sap_client_subnet_existing ? 0 : 1
  name                 = var.sap_client_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.sap_vnet_existing ? var.sap_vnet_name : azurerm_virtual_network.sap-vnet[0].name
  address_prefix       = var.sap_client_subnet_prefix
}

# Creates the sap app subnet
resource "azurerm_subnet" "sap-app-subnet" {
  count                = var.sap_app_subnet_existing ? 0 : 1
  name                 = var.sap_app_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.sap_vnet_existing ? var.sap_vnet_name : azurerm_virtual_network.sap-vnet[0].name
  address_prefix       = var.sap_app_subnet_prefix
}

# Creates management default subnet nsg
resource "azurerm_network_security_group" "mgmt-default-nsg" {
  count               = var.mgmt_default_nsg_existing ? 0 : 1
  name                = var.mgmt_default_nsg_name
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
}

# Creates sap admin subnet nsg
resource "azurerm_network_security_group" "sap-admin-nsg" {
  count               = var.sap_admin_nsg_existing ? 0 : 1
  name                = "${var.sap_admin_nsg_name}"
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
}

# Creates sap client subnet nsg
resource "azurerm_network_security_group" "sap-client-nsg" {
  count               = var.sap_client_nsg_existing ? 0 : 1
  name                = var.sap_client_nsg_name
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
}

# Creates sap app subnet nsg
resource "azurerm_network_security_group" "sap-app-nsg" {
  count               = var.sap_app_nsg_existing ? 0 : 1
  name                = "${var.sap_app_nsg_name}"
  location            = var.region
  resource_group_name = var.resource_group_existing ? var.resource_group_name : azurerm_resource_group.rg[0].name
}

# imports existing management vnet data
data "azurerm_virtual_network" "mgmt-vnet" {
  count               = var.mgmt_vnet_existing ? 1 : 0
  name                = var.mgmt_vnet_name
  resource_group_name = var.resource_group_name
}

# imports existing sap vnet data
data "azurerm_virtual_network" "sap-vnet" {
  count               = var.sap_vnet_existing ? 1 : 0
  name                = var.sap_vnet_name
  resource_group_name = var.resource_group_name
}

# Peers management vnet to sap vnet
resource "azurerm_virtual_network_peering" "mgmt-sap-peering" {
  count                        = signum((var.mgmt_vnet_existing ? 0 : 1) + (var.sap_vnet_existing ? 0 : 1))
  name                         = "${var.mgmt_vnet_name}-${var.sap_vnet_name}-peering"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.mgmt_vnet_existing ? var.mgmt_vnet_name : azurerm_virtual_network.mgmt-vnet[0].name
  remote_virtual_network_id    = var.sap_vnet_existing ? data.azurerm_virtual_network.sap-vnet[0].id : azurerm_virtual_network.sap-vnet[0].id
  allow_virtual_network_access = true
}

# peers sap vnet to management vnet
resource "azurerm_virtual_network_peering" "sap-mgmt-peering" {
  count                        = signum((var.mgmt_vnet_existing ? 0 : 1) + (var.sap_vnet_existing ? 0 : 1))
  name                         = "${var.sap_vnet_name}-${var.mgmt_vnet_name}-peering"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.sap_vnet_existing ? var.sap_vnet_name : azurerm_virtual_network.sap-vnet[0].name
  remote_virtual_network_id    = var.mgmt_vnet_existing ? data.azurerm_virtual_network.mgmt-vnet[0].id : azurerm_virtual_network.mgmt-vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
