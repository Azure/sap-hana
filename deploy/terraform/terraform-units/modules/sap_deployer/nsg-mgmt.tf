/*
Description:

  Define NSG for management vnet where deployer(s) resides.
*/

// Create/Import management nsg
resource "azurerm_network_security_group" "nsg-mgmt" {
  count               = local.enable_deployers && ! local.sub_mgmt_nsg_exists ? 1 : 0
  name                = local.sub_mgmt_nsg_name
  location            = azurerm_resource_group.deployer[0].location
  resource_group_name = azurerm_resource_group.deployer[0].name
}

data "azurerm_network_security_group" "nsg-mgmt" {
  count               = local.enable_deployers && local.sub_mgmt_nsg_exists ? 1 : 0
  name                = split("/", local.sub_mgmt_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_mgmt_nsg_arm_id)[4]
}

// Link management nsg with management vnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-mgmt" {
  count                     = local.enable_deployers ? signum((local.vnet_mgmt_exists ? 0 : 1) + (local.sub_mgmt_nsg_exists ? 0 : 1)) : 0
  subnet_id                 = local.sub_mgmt_deployed.id
  network_security_group_id = local.sub_mgmt_nsg_deployed.id
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr-ssh" {
  count                        = local.enable_deployers && ! local.sub_mgmt_nsg_exists ? 1 : 0
  name                         = "ssh"
  resource_group_name          = local.sub_mgmt_nsg_deployed.resource_group_name
  network_security_group_name  = local.sub_mgmt_nsg_deployed.name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = local.sub_mgmt_deployed.address_prefixes
}
