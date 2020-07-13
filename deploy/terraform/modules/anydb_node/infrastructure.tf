# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "anydb" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = format("%s-%s-avset", var.role, local.sid)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.ppgId
  managed                      = true
}

# Creates db subnet of SAP VNET
resource "azurerm_subnet" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 0 : 1) : 0
  name                 = local.sub_db_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.subnet_db.prefix]
}

# Imports data of existing any-db subnet
data "azurerm_subnet" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_db_arm_id)[10]
  resource_group_name  = split("/", local.sub_db_arm_id)[4]
  virtual_network_name = split("/", local.sub_db_arm_id)[8]
}

# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                 = local.sub_db_nsg_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
}

# Imports the SAP db subnet nsg data
data "azurerm_network_security_group" "anydb" {
  count               = local.enable_deployment ? (local.sub_db_nsg_exists ? 1 : 0) : 0
  name                = split("/", sub_db_nsg_arm_id)[8]
  resource_group_name = split("/", sub_db_nsg_arm_id)[4]
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "anydb" {
  count                     = local.enable_deployment ? signum((local.sub_db_exists ? 0 : 1) + (local.sub_db_nsg_exists ? 0 : 1)) : 0
  subnet_id                 = local.sub_db_exists ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
  network_security_group_id = local.sub_db_nsg_exists ? data.azurerm_network_security_group.anydb[0].id : azurerm_network_security_group.anydb[0].id
}
