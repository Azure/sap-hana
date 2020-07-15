/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s_xdb-alb", upper(local.anydb_sid))
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name                          = format("%s_xdb-feip", upper(local.anydb_sid))
    subnet_id                     = local.sub_db_exists ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.sub_db_exists ? try(local.anydb.loadbalancer.frontend_ip, cidrhost(local.sub_db_prefix, tonumber(count.index) + 4)) : cidrhost(local.sub_db_prefix, tonumber(count.index) + 4)
  }
}

resource "azurerm_lb_backend_address_pool" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
  name                = format("%s_xdbAlb-bePool", upper(local.anydb_sid))
}

resource "azurerm_lb_probe" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
  name                = format("%s_xdb-hp", upper(local.anydb_sid))
  port                = local.loadbalancer_ports[0].port
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface_backend_address_pool_association" "anydb" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.anydb) : 0
  network_interface_id    = azurerm_network_interface.anydb[count.index].id
  ip_configuration_name   = azurerm_network_interface.anydb[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.anydb[0].id
}

# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "anydb" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = format("%s_xdb-avset", local.anydb_sid)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.ppgId
  managed                      = true
}

# Creates db subnet of SAP VNET
resource "azurerm_subnet" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 0 : 1) : 0
  name                 = local.sub_db_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.sub_db_prefix]
}

# Imports data of existing any-db subnet
data "azurerm_subnet" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_db_arm_id)[10]
  resource_group_name  = split("/", local.sub_db_arm_id)[4]
  virtual_network_name = split("/", local.sub_db_arm_id)[8]
}

# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "anydb" {
  count               = local.enable_deployment ? (local.sub_db_nsg_exists ? 0 : 1) : 0
  name                = local.sub_db_nsg_name
  resource_group_name = var.vnet-sap[0].resource_group_name
  location            = var.vnet-sap[0].location
}

# Imports the SAP db subnet nsg data
data "azurerm_network_security_group" "anydb" {
  count               = local.enable_deployment ? (local.sub_db_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_db_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_db_nsg_arm_id)[4]
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "anydb" {
  count                     = local.enable_deployment ? signum((local.sub_db_exists ? 0 : 1) + (local.sub_db_nsg_exists ? 0 : 1)) : 0
  subnet_id                 = local.sub_db_exists ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
  network_security_group_id = local.sub_db_nsg_exists ? data.azurerm_network_security_group.anydb[0].id : azurerm_network_security_group.anydb[0].id
}
