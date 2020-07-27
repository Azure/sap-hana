# Creates SAP web subnet nsg
resource "azurerm_network_security_group" "nsg-web" {
  count               = local.enable_deployment && local.sub_web_defined ? (local.sub_web_nsg_exists ? 0 : 1) : 0
  name                = local.sub_web_nsg_name
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
}

# Imports the SAP web subnet nsg data
data "azurerm_network_security_group" "nsg-web" {
  count               = local.enable_deployment && local.sub_web_defined ? (local.sub_web_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_web_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_web_nsg_arm_id)[4]
}

# Associates SAP web nsg to SAP web subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-web" {
  count                     = local.enable_deployment && local.sub_web_defined ? (signum((local.sub_web_exists ? 0 : 1) + (local.sub_web_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_web_deployed.id
  network_security_group_id = local.sub_web_nsg_deployed.id
}

# NSG rule to deny internet access
resource "azurerm_network_security_rule" "webRule_internet" {
  count                        = local.enable_deployment ? (local.sub_web_nsg_exists ? 0 : 1) : 0
  name                         = "Internet"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Deny"
  protocol                     = "*"
  source_address_prefix        = "Internet"
  source_port_range            = "*"
  destination_address_prefixes = local.sub_web_deployed.address_prefixes
  destination_port_range       = "*"
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.sub_web_nsg_deployed.name
}

# NSG rule to open ports for Web dispatcher
resource "azurerm_network_security_rule" "web" {
  count                        = local.enable_deployment ? (local.sub_web_nsg_exists ? 0 : length(local.nsg-ports.web)) : 0
  name                         = local.nsg-ports.web[count.index].name
  priority                     = local.nsg-ports.web[count.index].priority
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_address_prefixes      = var.subnet-mgmt[0].address_prefixes
  source_port_range            = "*"
  destination_address_prefixes = local.sub_web_deployed.address_prefixes
  destination_port_range       = local.nsg-ports.web[count.index].port
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.sub_web_nsg_deployed.name
}
