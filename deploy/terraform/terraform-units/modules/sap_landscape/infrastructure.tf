/*
  Description:
  Setup infrastructure for sap landscape
*/

// Creates the resource group
resource "azurerm_resource_group" "resource_group" {
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
}

// Imports data of existing resource group
data "azurerm_resource_group" "resource_group" {
  count = local.rg_exists ? 1 : 0
  name  = local.rg_name
}

// Creates the SAP VNET
resource "azurerm_virtual_network" "vnet_sap" {
  count               = local.vnet_sap_exists ? 0 : 1
  name                = local.vnet_sap_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  address_space       = [local.vnet_sap_addr]
}

// Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  count               = local.vnet_sap_exists ? 1 : 0
  name                = split("/", local.vnet_sap_arm_id)[8]
  resource_group_name = split("/", local.vnet_sap_arm_id)[4]
}

// Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering_management_sap" {
  count                        = local.vnet_sap_exists ? 0 : 1
  name                         = substr(format("%s_to_%s", local.vnet_mgmt.name, local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name), 0, 80)
  resource_group_name          = local.vnet_mgmt.resource_group_name
  virtual_network_name         = local.vnet_mgmt.name
  remote_virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].id : azurerm_virtual_network.vnet_sap[0].id
  allow_virtual_network_access = true
}

// Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering_sap_management" {
  count                        = local.vnet_sap_exists ? 0 : 1
  name                         = substr(format("%s_to_%s", local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name, local.vnet_mgmt.name), 0, 80)
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name         = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  remote_virtual_network_id    = local.vnet_mgmt.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

// Creates boot diagnostics storage account
resource "azurerm_storage_account" "storage_bootdiag" {
  name                      = local.storageaccount_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}
