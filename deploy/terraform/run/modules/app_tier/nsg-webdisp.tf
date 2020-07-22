# NSG rule to deny internet access
resource azurerm_network_security_rule webRule_internet {
  count                        = local.enable_deployment ? (local.sub_app_nsg_exists ? 0 : 1) : 0
  name                         = "Internet"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Deny"
  protocol                     = "*"
  source_address_prefix        = "Internet"
  source_port_range            = "*"
  destination_address_prefixes = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].address_prefixes : azurerm_subnet.subnet-sap-app[0].address_prefixes
  destination_port_range       = "*"
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].name : azurerm_network_security_group.nsg-app[0].name
}

# NSG rule to open ports for Web dispatcher
resource azurerm_network_security_rule web {
  count                        = local.enable_deployment ? (local.sub_app_nsg_exists ? 0 : length(local.nsg-ports.web)) : 0
  name                         = local.nsg-ports.web[count.index].name
  priority                     = local.nsg-ports.web[count.index].priority
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_address_prefixes      = var.subnet-mgmt[0].address_prefixes
  source_port_range            = "*"
  destination_address_prefixes = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].address_prefixes : azurerm_subnet.subnet-sap-app[0].address_prefixes
  destination_port_range       = local.nsg-ports.web[count.index].port
  resource_group_name          = var.resource-group[0].name
  network_security_group_name  = local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].name : azurerm_network_security_group.nsg-app[0].name
}
