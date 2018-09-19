data "http" "local_ip" {
  url = "http://api.ipify.org"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "sap-nsg" {
  name                = "${var.sap_sid}-nsg"
  location            = "${var.az_region}"
  resource_group_name = "${var.resource_group_name}"

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
    environment = "Terraform SAP HANA single node deployment nsg"
  }
}

resource "azurerm_network_security_rule" "hana1-http" {
  count                       = "${!var.useHana2 ? 1 : 0}"
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
  count                       = "${!var.useHana2 ? 1 : 0}"
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

# Specify that those are for HANA 2 and XSA only
resource "azurerm_network_security_rule" "hana2-xsa-http" {
  count                       = "${var.useHana2 ? 1 : 0}"
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

resource "azurerm_network_security_rule" "hana2-xsa" {
  count                       = "${var.useHana2 ? 1 : 0}"
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
