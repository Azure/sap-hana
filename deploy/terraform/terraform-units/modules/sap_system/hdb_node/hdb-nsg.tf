// Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_internal_db" {
  count                        = local.enable_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                         = "allow-internal-traffic"
  resource_group_name          = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].resource_group_name : azurerm_network_security_group.db[0].resource_group_name
  network_security_group_name  = local.sub_db_nsg_exists ? data.azurerm_network_security_group.db[0].name : azurerm_network_security_group.db[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = local.vnet_sap_address_space
  destination_address_prefixes = local.sub_db_exists ? data.azurerm_subnet.sap_db[0].address_prefixes : azurerm_subnet.sap_db[0].address_prefixes
}

// Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_external_db" {
  count                        = local.enable_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
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
  destination_address_prefixes = local.sub_db_exists ? data.azurerm_subnet.sap_db[0].address_prefixes : azurerm_subnet.sap_db[0].address_prefixes
}
