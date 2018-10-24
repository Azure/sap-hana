# This gets the IP address of the machine you deploy from.
data "http" "local_ip" {
  url = "http://api.ipify.org"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "sap-nsg" {
  count               = "${var.use_existing_nsg ? 1 : 0}"
  name                = "${var.sap_sid}-nsg"
  location            = "${var.az_region}"
  resource_group_name = "${var.resource_group_name}"

  # This rule lets you ssh to the Database VMs
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # This rule specifically allows the machine you use to deploy to access the VMs
  security_rule {
    name                       = "local-ip-allow-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${chomp(data.http.local_ip.body)}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "open-hana-db-ports"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3${var.sap_instancenum}00-3${var.sap_instancenum}99"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Terraform SAP HANA deployment nsg"
  }
}

# The Ports that HANA 1 uses are different from the ones HANA 2 uses
resource "azurerm_network_security_rule" "hana1-http" {
  count                       = "${var.use_existing_nsg ? (!var.useHana2 ? 1 : 0) : 0}" # The rule is only created if we use HANA 1 and are creating a new NSG
  name                        = "HTTP"
  priority                    = 1030
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80${var.sap_instancenum}"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.sap-nsg.name}"
}

resource "azurerm_network_security_rule" "hana1-https" {
  count                       = "${var.use_existing_nsg ? (!var.useHana2 ? 1 : 0) : 0}" # The rule is only created if we use HANA 1 and are creating a new NSG
  name                        = "HTTPS"
  priority                    = 1040
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "43${var.sap_instancenum}"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.sap-nsg.name}"
}

# The rule is only created if we use HANA 2 and are creating a new NSG
resource "azurerm_network_security_rule" "hana2-xsa-http" {
  count                       = "${var.use_existing_nsg ? (var.useHana2 ? 1 : 0) : 0}"
  name                        = "XSA-HTTP"
  priority                    = 1030
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "4000-4999"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.sap-nsg.name}"
}

# The rule is only created if we use HANA 2 and are creating a new NSG
resource "azurerm_network_security_rule" "hana2-xsa" {
  count                       = "${var.use_existing_nsg ? (var.useHana2 ? 1 : 0) : 0}"
  name                        = "XSA"
  priority                    = 1040
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000-59999"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.sap-nsg.name}"
}
