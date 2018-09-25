resource "azurerm_network_security_group" "windows_group" {
  count               = "${var.isLinux ? 0 : 1}"
  name                = "windows_bastion_nsg"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "windows_bastion"
  }
}

resource "azurerm_network_security_group" "linux_group" {
  count               = "${var.isLinux ? 1 : 0}"
  name                = "linux_bastion_nsg"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "VNC"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "linux_bastion"
  }
}
