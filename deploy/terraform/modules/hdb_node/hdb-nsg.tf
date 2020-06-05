/*-----------------------------------------------------------------------------8
|                                                                              |
|                                 HANA - NSG                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/

# Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr-internal-db" {
  count                       = var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 0 : 1
  name                        = "allow-internal-traffic"
  resource_group_name         = var.nsg-db[0].resource_group_name
  network_security_group_name = var.nsg-db[0].name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.infrastructure.vnets.sap.address_space
  destination_address_prefix  = var.infrastructure.vnets.sap.subnet_db.prefix
}

# Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr-external-db" {
  count                       = var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 0 : 1
  name                        = "deny-inbound-traffic"
  resource_group_name         = var.nsg-db[0].resource_group_name
  network_security_group_name = var.nsg-db[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = var.infrastructure.vnets.sap.subnet_db.prefix
}

# Creates network security rule for SAP admin subnet
resource "azurerm_network_security_rule" "nsr-admin" {
  count                       = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 0 : 1
  name                        = "nsr-subnet-admin"
  resource_group_name         = var.nsg-admin[0].resource_group_name
  network_security_group_name = var.nsg-admin[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.infrastructure.vnets.management.subnet_mgmt.prefix
  destination_address_prefix  = var.infrastructure.vnets.sap.subnet_admin.prefix
}
