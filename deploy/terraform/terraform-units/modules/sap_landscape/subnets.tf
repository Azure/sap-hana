// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  provider             = azurerm.main
  count                = local.sub_admin_defined && !local.sub_admin_existing ? 1 : 0
  name                 = local.sub_admin_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_admin_prefix]
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

// Creates app subnet of SAP VNET
resource "azurerm_subnet" "app" {
  provider             = azurerm.main
  count                = local.sub_app_defined && !local.sub_app_existing ? 1 : 0
  name                 = local.sub_app_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_app_prefix]
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

// Creates anf subnet of SAP VNET
resource "azurerm_subnet" "anf" {
  provider             = azurerm.main
  count                = local.sub_anf_defined && !local.sub_anf_existing ? 1 : 0
  name                 = local.sub_anf_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.sub_anf_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      actions = [
        "Microsoft.Network/networkinterfaces/*",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
      name = "Microsoft.Netapp/volumes"
    }
  }

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
  provider = azurerm.main
  count    = local.sub_admin_defined && !local.sub_admin_nsg_exists ? 1 : 0

  subnet_id                 = local.sub_admin_existing ? local.sub_admin_arm_id : azurerm_subnet.admin[0].id
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
  subnet_id                 = local.sub_db_existing ? local.sub_db_arm_id : azurerm_subnet.db[0].id
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
  subnet_id                 = local.sub_app_existing ? local.sub_app_arm_id : azurerm_subnet.app[0].id
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
  subnet_id                 = local.sub_web_existing ? local.sub_web_arm_id : azurerm_subnet.web[0].id
  network_security_group_id = azurerm_network_security_group.web[0].id
}

#Associate the subnets to the route table

resource "azurerm_subnet_route_table_association" "admin" {
  depends_on = [
    azurerm_route_table.rt
  ]

  provider       = azurerm.main
  count          = local.sub_admin_defined && !local.sub_admin_existing ? 1 : 0
  subnet_id      = local.sub_admin_existing ? local.sub_admin_arm_id : azurerm_subnet.admin[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "db" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.sub_db_defined && !local.sub_db_existing ? 1 : 0
  subnet_id      = local.sub_db_existing ? local.sub_db_arm_id : azurerm_subnet.db[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "app" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.sub_app_defined && !local.sub_app_existing ? 1 : 0
  subnet_id      = local.sub_app_existing ? local.sub_app_arm_id : azurerm_subnet.app[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "web" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.sub_web_defined && !local.sub_web_existing ? 1 : 0
  subnet_id      = local.sub_web_existing ? local.sub_web_arm_id : azurerm_subnet.web[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

