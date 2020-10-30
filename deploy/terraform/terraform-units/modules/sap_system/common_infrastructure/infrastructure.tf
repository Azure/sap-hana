##################################################################################################################
# RESOURCES
##################################################################################################################

# RESOURCE GROUP =================================================================================================

# Creates the resource group
resource "azurerm_resource_group" "resource-group" {
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
}

# Imports data of existing resource group
data "azurerm_resource_group" "resource-group" {
  count = local.rg_exists ? 1 : 0
  name  = split("/", local.rg_arm_id)[4]
}

# VNETs ==========================================================================================================

# Creates the SAP VNET
resource "azurerm_virtual_network" "vnet-sap" {
  count               = local.vnet_sap_exists ? 0 : 1
  name                = local.vnet_sap_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [local.vnet_sap_addr]
}

# Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet-sap" {
  count               = local.vnet_sap_exists ? 1 : 0
  name                = split("/", local.vnet_sap_arm_id)[8]
  resource_group_name = split("/", local.vnet_sap_arm_id)[4]
}

// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  count                = ! local.sub_admin_exists && local.enable_admin_subnet ? 1 : 0
  name                 = local.sub_admin_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name
  address_prefixes     = [local.sub_admin_prefix]
}

# Imports data of existing SAP admin subnet
data "azurerm_subnet" "admin" {
  count                = local.sub_admin_exists && local.enable_admin_subnet ? 1 : 0
  name                 = split("/", local.sub_admin_arm_id)[10]
  resource_group_name  = split("/", local.sub_admin_arm_id)[4]
  virtual_network_name = split("/", local.sub_admin_arm_id)[8]
}

# Creates SAP admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  count               = local.sub_admin_nsg_exists && local.enable_admin_subnet ? 0 : 1
  name                = local.sub_admin_nsg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
}

# Imports the SAP admin subnet nsg data
data "azurerm_network_security_group" "admin" {
  count               = local.sub_admin_nsg_exists && local.enable_admin_subnet ? 1 : 0
  name                = split("/", local.sub_admin_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_admin_nsg_arm_id)[4]
}

# Associates SAP admin nsg to SAP admin subnet
resource "azurerm_subnet_network_security_group_association" "Associate-admin" {
  count                     = local.enable_admin_subnet ? (signum((local.sub_admin_exists ? 0 : 1) + (local.sub_admin_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_admin_exists ? data.azurerm_subnet.admin[0].id : azurerm_subnet.admin[0].id
  network_security_group_id = local.sub_admin_nsg_exists ? data.azurerm_network_security_group.admin[0].id : azurerm_network_security_group.admin[0].id
}


# VNET PEERINGs ==================================================================================================

# Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering-management-sap" {
  count                        = local.vnet_sap_exists ? 0 : 1
  name                         = substr(format("%s_to_%s", local.vnet-mgmt.name, local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name), 0, 80)
  resource_group_name          = local.vnet-mgmt.resource_group_name
  virtual_network_name         = local.vnet-mgmt.name
  remote_virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
  allow_virtual_network_access = true
}

# Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering-sap-management" {
  count                        = local.vnet_sap_exists ? 0 : 1
  name                         = substr(format("%s_to_%s", local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name, local.vnet-mgmt.name), 0, 80)
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name
  virtual_network_name         = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name
  remote_virtual_network_id    = local.vnet-mgmt.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# STORAGE ACCOUNTS ===============================================================================================

# Creates boot diagnostics storage account
resource "azurerm_storage_account" "storage-bootdiag" {
  name                      = local.storageaccount_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}


# PROXIMITY PLACEMENT GROUP ===============================================================================================

resource "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? 0 : (local.zonal_deployment ? max(length(local.zones), 1) : 1)
  name                = local.zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.zones[count.index], local.resource_suffixes.ppg) : local.ppg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
}


data "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? 1 : 0
  name                = split("/", local.ppg_arm_id)[8]
  resource_group_name = split("/", local.ppg_arm_id)[4]
}
