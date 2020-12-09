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

// Imports data of Landscape SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  name                = local.vnet_sap_name
  resource_group_name = local.vnet_sap_resource_group_name
}

// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  count                = ! local.sub_admin_exists && local.enable_admin_subnet ? 1 : 0
  name                 = local.sub_admin_name
  resource_group_name  = local.vnet_sap_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_admin_prefix]
}

// Imports data of existing SAP admin subnet
data "azurerm_subnet" "admin" {
  count                = local.sub_admin_exists && local.enable_admin_subnet ? 1 : 0
  name                 = split("/", local.sub_admin_arm_id)[10]
  resource_group_name  = split("/", local.sub_admin_arm_id)[4]
  virtual_network_name = split("/", local.sub_admin_arm_id)[8]
}

// Creates db subnet of SAP VNET
resource "azurerm_subnet" "db" {
  count                = local.enable_db_deployment ? (local.sub_db_exists ? 0 : 1) : 0
  name                 = local.sub_db_name
  resource_group_name  = local.vnet_sap_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_db_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "db" {
  count                = local.enable_db_deployment ? (local.sub_db_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_db_arm_id)[10]
  resource_group_name  = split("/", local.sub_db_arm_id)[4]
  virtual_network_name = split("/", local.sub_db_arm_id)[8]
}

// Scale out on ANF
resource "azurerm_subnet" "storage" {
  count                = local.enable_db_deployment && local.enable_storage_subnet ? (local.sub_storage_exists ? 0 : 1) : 0
  name                 = local.sub_storage_name
  resource_group_name  = local.vnet_sap_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_storage_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "storage" {
  count                = local.enable_db_deployment && local.enable_storage_subnet ? (local.sub_storage_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_storage_arm_id)[10]
  resource_group_name  = split("/", local.sub_storage_arm_id)[4]
  virtual_network_name = split("/", local.sub_storage_arm_id)[8]
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

// PROXIMITY PLACEMENT GROUP
resource "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? 0 : (local.zonal_deployment ? max(length(local.zones), 1) : 1)
  name                = local.zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.zones[count.index], local.resource_suffixes.ppg) : local.ppg_names[count.index]
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
}

data "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? max(length(local.zones), 1) : 0
  name                = split("/", local.ppg_arm_ids[count.index])[8]
  resource_group_name = split("/", local.ppg_arm_ids[count.index])[4]
}
