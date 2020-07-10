# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-web" {
  count               = local.enable_deployment ? (local.var_sub_web_defined ? (local.sub_web_nsg_exists ? 0 : 1) : 0) : 0
  name                = local.sub_app_nsg_name
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-web" {
  count               = local.enable_deployment ? (local.var_sub_web_defined ? (local.sub_web_nsg_exists ? 1 : 0) : 0) : 0
  name                = split("/", local.sub_web_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_web_nsg_arm_id)[4]
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-web" {
  count                     = local.enable_deployment ? local.var_sub_web_defined ? (signum((local.sub_web_exists ? 0 : 1) + (local.sub_app_nsg_exists ? 0 : 1))): (signum((local.sub_app_exists ? 0 : 1) + (local.sub_app_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.var_sub_web_defined ? (local.sub_web_exists ? data.azurerm_subnet.subnet-sap-web[0].id : azurerm_subnet.subnet-sap-web[0].id) : (local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id)
  network_security_group_id = local.var_sub_web_defined ? (local.sub_web_nsg_exists ? data.azurerm_network_security_group.nsg-web[0].id : azurerm_network_security_group.nsg-web[0].id) : (local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id)
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
  destination_address_prefixes = local.var_sub_web_defined ? (local.sub_web_exists ? data.azurerm_subnet.subnet-sap-web[0].address_prefixes : azurerm_subnet.subnet-sap-web[0].address_prefixes) : (local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].address_prefixes : azurerm_subnet.subnet-sap-app[0].address_prefixes)
  destination_port_range       = "*"
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.var_sub_web_defined ? (local.sub_web_nsg_exists ? data.azurerm_network_security_group.nsg-web[0].name : azurerm_network_security_group.nsg-web[0].name) : (local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].name : azurerm_network_security_group.nsg-app[0].name)
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
  destination_address_prefixes = local.var_sub_web_defined ? (local.sub_web_exists ? data.azurerm_subnet.subnet-sap-web[0].address_prefixes : azurerm_subnet.subnet-sap-web[0].address_prefixes) : (local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].address_prefixes : azurerm_subnet.subnet-sap-app[0].address_prefixes)
  destination_port_range       = local.nsg-ports.web[count.index].port
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.var_sub_web_defined ? (local.sub_web_nsg_exists ? data.azurerm_network_security_group.nsg-web[0].name : azurerm_network_security_group.nsg-web[0].name) : (local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].name : azurerm_network_security_group.nsg-app[0].name)
}
