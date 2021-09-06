/*
Description:

  Define NSG for management vnet where deployer(s) resides.
*/

// Create/Import management nsg
resource "azurerm_network_security_group" "nsg_mgmt" {
  count               = local.enable_deployers && !local.sub_mgmt_nsg_exists ? 1 : 0
  name                = local.sub_mgmt_nsg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
}

data "azurerm_network_security_group" "nsg_mgmt" {
  count               = local.enable_deployers && local.sub_mgmt_nsg_exists ? 1 : 0
  name                = split("/", local.sub_mgmt_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_mgmt_nsg_arm_id)[4]
}

// Link management nsg with management vnet
resource "azurerm_subnet_network_security_group_association" "associate_nsg_mgmt" {
  depends_on = [
    azurerm_network_security_rule.nsr_ssh,
    azurerm_network_security_rule.nsr_rdp,
    azurerm_network_security_rule.nsr_winrm

  ]
  count                     = (local.enable_deployers && !local.sub_mgmt_exists) ? 1 : 0
  subnet_id                 = local.sub_mgmt_exists ? data.azurerm_subnet.subnet_mgmt[0].id : azurerm_subnet.subnet_mgmt[0].id
  network_security_group_id = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].id : azurerm_network_security_group.nsg_mgmt[0].id
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh" {
  depends_on = [
    data.azurerm_network_security_group.nsg_mgmt,
    azurerm_network_security_group.nsg_mgmt
  ]
  count                        = !local.sub_mgmt_nsg_exists ? 1 : 0
  name                         = "ssh"
  resource_group_name          = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name : azurerm_network_security_group.nsg_mgmt[0].resource_group_name
  network_security_group_name  = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].name : azurerm_network_security_group.nsg_mgmt[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = local.sub_mgmt_deployed.address_prefixes
}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp" {
  depends_on = [
    data.azurerm_network_security_group.nsg_mgmt,
    azurerm_network_security_group.nsg_mgmt
  ]
  count                        = !local.sub_mgmt_nsg_exists ? 1 : 0
  name                         = "rdp"
  resource_group_name          = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name : azurerm_network_security_group.nsg_mgmt[0].resource_group_name
  network_security_group_name  = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].name : azurerm_network_security_group.nsg_mgmt[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 3389
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = local.sub_mgmt_deployed.address_prefixes
}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm" {
  depends_on = [
    data.azurerm_network_security_group.nsg_mgmt,
    azurerm_network_security_group.nsg_mgmt
  ]
  count                        = !local.sub_mgmt_nsg_exists ? 1 : 0
  name                         = "winrm"
  resource_group_name          = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name : azurerm_network_security_group.nsg_mgmt[0].resource_group_name
  network_security_group_name  = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0].name : azurerm_network_security_group.nsg_mgmt[0].name
  priority                     = 103
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = [5985, 5986]
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = local.sub_mgmt_deployed.address_prefixes
}
