/*-----------------------------------------------------------------------------8
|                                                                              |
|                                 HANA - NSG                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/

# Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_internal_db" {
  count                        = local.enable_hdb_deployment || local.enable_xdb_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                         = "allow-internal-traffic"
  resource_group_name          = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].resource_group_name : azurerm_network_security_group.db[0].resource_group_name
  network_security_group_name  = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].name : azurerm_network_security_group.db[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].address_space : azurerm_virtual_network.vnet_sap[0].address_space
  destination_address_prefixes = local.sub_db_exists ? data.azurerm_subnet.db[0].address_prefixes : azurerm_subnet.db[0].address_prefixes
}

# Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_external_db" {
  count                        = local.enable_hdb_deployment || local.enable_xdb_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                         = "deny-inbound-traffic"
  resource_group_name          = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].resource_group_name : azurerm_network_security_group.db[0].resource_group_name
  network_security_group_name  = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].name : azurerm_network_security_group.db[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "deny"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefix        = "*"
  destination_address_prefixes = local.sub_db_exists ? data.azurerm_subnet.db[0].address_prefixes : azurerm_subnet.db[0].address_prefixes
}

# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  count               = local.enable_hdb_deployment || local.enable_xdb_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                = local.sub_db_nsg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
}

# Imports the SAP db subnet nsg data
data "azurerm_network_security_group" "db" {
  count               = local.enable_hdb_deployment || local.enable_xdb_deployment ? (local.sub_db_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_db_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_db_nsg_arm_id)[4]
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  count                     = local.enable_hdb_deployment || local.enable_xdb_deployment ? signum((local.sub_db_exists ? 0 : 1) + (local.sub_db_nsg_exists ? 0 : 1)) : 0
  subnet_id                 = local.sub_db_exists ? data.azurerm_subnet.db[0].id : azurerm_subnet.db[0].id
  network_security_group_id = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].id : azurerm_network_security_group.db[0].id
}

# Creates SAP admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  count               = ! local.sub_admin_nsg_exists && local.enable_admin_subnet ? 0 : 1
  name                = local.sub_admin_nsg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
}

# Imports the SAP admin subnet nsg data
data "azurerm_network_security_group" "admin" {
  count               = local.sub_admin_nsg_exists && local.enable_admin_subnet ? 1 : 0
  name                = split("/", local.sub_admin_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_admin_nsg_arm_id)[4]
}

# Associates SAP admin nsg to SAP admin subnet
resource "azurerm_subnet_network_security_group_association" "admin" {
  count                     = local.enable_admin_subnet ? (signum((local.sub_admin_exists ? 0 : 1) + (local.sub_admin_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_admin_exists ? data.azurerm_subnet.admin[0].id : azurerm_subnet.admin[0].id
  network_security_group_id = local.sub_admin_nsg_exists ? data.azurerm_network_security_group.admin[0].id : azurerm_network_security_group.admin[0].id
}
