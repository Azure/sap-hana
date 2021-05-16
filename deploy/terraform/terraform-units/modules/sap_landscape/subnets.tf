// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  provider             = azurerm.main
  count                = local.sub_admin_defined && !local.sub_admin_existing ? 1 : 0
  name                 = local.sub_admin_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_admin_prefix]
}

resource "azurerm_subnet_route_table_association" "admin" {
  provider       = azurerm.main
  count          = local.sub_admin_defined && !local.sub_admin_existing && !local.vnet_sap_exists ? 1 : 0
  subnet_id      = local.sub_admin_existing ? local.sub_admin_id : azurerm_subnet.admin[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

// Creates db subnet of SAP VNET
resource "azurerm_subnet" "db" {
  provider             = azurerm.main
  count                = local.sub_db_defined && !local.sub_db_existing ? 1 : 0
  name                 = local.sub_db_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_db_prefix]
}

resource "azurerm_subnet_route_table_association" "db" {
  provider       = azurerm.main
  count          = local.sub_db_defined && !local.sub_db_existing && !local.vnet_sap_exists ? 1 : 0
  subnet_id      = local.sub_db_existing ? local.sub_db_id : azurerm_subnet.db[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

// Creates app subnet of SAP VNET
resource "azurerm_subnet" "app" {
  provider             = azurerm.main
  count                = local.sub_app_defined && !local.sub_app_existing ? 1 : 0
  name                 = local.sub_app_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_app_prefix]
}

resource "azurerm_subnet_route_table_association" "app" {
  provider       = azurerm.main
  count          = local.sub_app_defined && !local.sub_app_existing && !local.vnet_sap_exists ? 1 : 0
  subnet_id      = local.sub_app_existing ? local.sub_app_id : azurerm_subnet.app[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

// Creates web subnet of SAP VNET
resource "azurerm_subnet" "web" {
  provider             = azurerm.main
  count                = local.sub_web_defined && !local.sub_web_existing ? 1 : 0
  name                 = local.sub_web_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_web_prefix]
}

resource "azurerm_subnet_route_table_association" "web" {
  provider       = azurerm.main
  count          = local.sub_web_defined && !local.sub_web_existing && !local.vnet_sap_exists ? 1 : 0
  subnet_id      = local.sub_web_existing ? local.sub_web_id : azurerm_subnet.web[0].id
  route_table_id = azurerm_route_table.rt[0].id
}


# Creates admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  provider            = azurerm.main
  count               = local.sub_admin_defined && !local.sub_admin_nsg_exists ? 1 : 0
  name                = local.sub_admin_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates admin nsg to admin subnet
resource "azurerm_subnet_network_security_group_association" "admin" {
  provider                  = azurerm.main
  count                     = local.sub_admin_defined && !local.sub_admin_nsg_exists ? 1 : 0
   
  subnet_id                 = local.sub_admin_existing ? local.sub_admin_id : azurerm_subnet.admin[0].id
  network_security_group_id = azurerm_network_security_group.admin[0].id
}


# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  provider            = azurerm.main
  count               = local.sub_db_defined && !local.sub_db_nsg_exists ? 1 : 0
  name                = local.sub_db_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  provider                  = azurerm.main
  count                     = local.sub_db_defined && !local.sub_db_nsg_exists ? 1 : 0
  subnet_id                 = local.sub_db_existing ? local.sub_db_id : azurerm_subnet.db[0].id
  network_security_group_id = azurerm_network_security_group.db[0].id
}


# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "app" {
  provider            = azurerm.main
  count               = local.sub_app_defined && !local.sub_app_nsg_exists ? 1 : 0
  name                = local.sub_app_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates app nsg to app subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  provider                  = azurerm.main
  count                     = local.sub_app_defined && !local.sub_app_nsg_exists ? 1 : 0
  subnet_id                 = local.sub_app_existing ? local.sub_app_id : azurerm_subnet.app[0].id
  network_security_group_id = azurerm_network_security_group.app[0].id
}


# Creates SAP web subnet nsg
resource "azurerm_network_security_group" "web" {
  provider            = azurerm.main
  count               = local.sub_web_defined && !local.sub_web_nsg_exists ? 1 : 0
  name                = local.sub_web_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates SAP web nsg to SAP web subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  provider                  = azurerm.main
  count                     = local.sub_web_defined && !local.sub_web_nsg_exists ? 1 : 0
  subnet_id                 = local.sub_web_existing ? local.sub_web_id : azurerm_subnet.web[0].id
  network_security_group_id = azurerm_network_security_group.web[0].id
}

########################################################################################################
#
# Create a Azure Firewall Network Rule for Azure Management API and Outbound Internet
#
########################################################################################################

resource "random_integer" "app_priority" {
  min = 3000
  max = 3999
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = local.firewall_rgname
  }
}
resource "azurerm_firewall_network_rule_collection" "firewall-azure-app" {
  provider            = azurerm.deployer
  count               = local.firewall_exists && local.sub_app_defined && !local.sub_app_existing ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.firewall_rule_app)
  azure_firewall_name = local.firewall_name
  resource_group_name = local.firewall_rgname
  priority            = random_integer.app_priority.result
  action              = "Allow"
  rule {
    name                  = "Azure-Cloud"
    source_addresses      = local.sub_web_defined ? [local.sub_app_prefix, local.sub_web_prefix] : [local.sub_app_prefix]
    destination_ports     = ["*"]
    destination_addresses = [local.firewall_service_tags]
    protocols             = ["Any"]
  }
  rule {
    name                  = "ToInternet"
    source_addresses      = local.sub_web_defined ? [local.sub_app_prefix, local.sub_web_prefix] : [local.sub_app_prefix]
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["Any"]
  }
}

########################################################################################################
#
# Create a Azure Firewall Network Rule for Azure Management API and Outbound Internet
#
########################################################################################################


resource "random_integer" "db_priority" {
  min = 2000
  max = 2999
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = local.firewall_rgname
  }
}


# Create a Azure Firewall Network Rule for Azure Management API
resource "azurerm_firewall_network_rule_collection" "firewall-azure-db" {
  provider            = azurerm.deployer
  count               = local.firewall_exists && local.sub_db_defined && !local.sub_db_nsg_exists ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.firewall_rule_db)
  azure_firewall_name = local.firewall_name
  resource_group_name = local.firewall_rgname
  priority            = random_integer.db_priority.result
  action              = "Allow"
  rule {
    name                  = "Azure-Cloud"
    source_addresses      = [local.sub_admin_prefix, local.sub_db_prefix]
    destination_ports     = ["*"]
    destination_addresses = [local.firewall_service_tags]
    protocols             = ["Any"]
  }
  rule {
    name                  = "ToInternet"
    source_addresses      = [local.sub_admin_prefix, local.sub_db_prefix]
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["Any"]
  }
}
