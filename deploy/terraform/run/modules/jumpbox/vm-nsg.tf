/*-----------------------------------------------------------------------------8
|                                                                              |
|                              JUMPBOX - NSG                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/

# Creates Windows jumpbox RDP network security rule
resource "azurerm_network_security_rule" "nsr-rdp" {
  count                        = local.sub_mgmt_nsg_exists ? 0 : 1
  name                         = "rdp"
  resource_group_name          = var.nsg-mgmt[0].resource_group_name
  network_security_group_name  = var.nsg-mgmt[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 3389
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = var.subnet-mgmt[0].address_prefixes
}

# Creates Windows jumpbox WinRM network security rule
resource "azurerm_network_security_rule" "nsr-winrm" {
  count                        = local.sub_mgmt_nsg_exists ? 0 : 1
  name                         = "winrm"
  resource_group_name          = var.nsg-mgmt[0].resource_group_name
  network_security_group_name  = var.nsg-mgmt[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = [5985, 5986]
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = var.subnet-mgmt[0].address_prefixes
}

# Creates Linux jumpbox and RTI box SSH network security rule
resource "azurerm_network_security_rule" "nsr-ssh" {
  count                        = local.sub_mgmt_nsg_exists ? 0 : 1
  name                         = "ssh"
  resource_group_name          = var.nsg-mgmt[0].resource_group_name
  network_security_group_name  = var.nsg-mgmt[0].name
  priority                     = 103
  direction                    = "Inbound"
  access                       = "allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = local.sub_mgmt_nsg_allowed_ips
  destination_address_prefixes = var.subnet-mgmt[0].address_prefixes
}
