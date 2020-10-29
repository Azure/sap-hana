# Creates admin subnet of SAP VNET
resource "azurerm_subnet" "sap-admin" {
  count                = local.enable_deployment ? (local.sub_admin_exists ? 0 : 1) : 0
  name                 = local.sub_admin_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.sub_admin_prefix]
}

# Creates db subnet of SAP VNET
resource "azurerm_subnet" "sap-db" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 0 : 1) : 0
  name                 = local.sub_db_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.sub_db_prefix]
}

# Imports data of existing SAP admin subnet
data "azurerm_subnet" "sap-admin" {
  count                = local.enable_deployment ? (local.sub_admin_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_admin_arm_id)[10]
  resource_group_name  = split("/", local.sub_admin_arm_id)[4]
  virtual_network_name = split("/", local.sub_admin_arm_id)[8]
}

# Imports data of existing SAP db subnet
data "azurerm_subnet" "sap-db" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_db_arm_id)[10]
  resource_group_name  = split("/", local.sub_db_arm_id)[4]
  virtual_network_name = split("/", local.sub_db_arm_id)[8]
}

# Creates SAP admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  count               = local.enable_deployment ? (local.sub_admin_nsg_exists ? 0 : 1) : 0
  name                = local.sub_admin_nsg_name
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location
}

# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  count               = local.enable_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                = local.sub_db_nsg_name
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location
}

# Imports the SAP admin subnet nsg data
data "azurerm_network_security_group" "admin" {
  count               = local.enable_deployment ? (local.sub_admin_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_admin_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_admin_nsg_arm_id)[4]
}

# Imports the SAP db subnet nsg data
data "azurerm_network_security_group" "db" {
  count               = local.enable_deployment ? (local.sub_db_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_db_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_db_nsg_arm_id)[4]
}

# Associates SAP admin nsg to SAP admin subnet
resource "azurerm_subnet_network_security_group_association" "Associate-admin" {
  count                     = local.enable_deployment ? (signum((local.sub_admin_exists ? 0 : 1) + (local.sub_admin_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_admin_exists ? data.azurerm_subnet.sap-admin[0].id : azurerm_subnet.sap-admin[0].id
  network_security_group_id = local.sub_admin_nsg_exists ? data.azurerm_network_security_group.admin[0].id : azurerm_network_security_group.admin[0].id
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "Associate-db" {
  count                     = local.enable_deployment ? (signum((local.sub_db_exists ? 0 : 1) + (local.sub_db_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_db_exists ? data.azurerm_subnet.sap-db[0].id : azurerm_subnet.sap-db[0].id
  network_security_group_id = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].id : azurerm_network_security_group.db[0].id
}


# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "hdb" {
  count                        = local.enable_deployment ? max(length(local.zones), 1) : 0
  name                         = local.zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.zones[count.index], local.resource_suffixes.db-avset) : format("%s%s", local.prefix, local.resource_suffixes.db-avset)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % length(local.zones)].id : var.ppg[0].id
  managed                      = true
}
