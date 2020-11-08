/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "anydb" {
  count = local.enable_deployment ? 1 : 0
  name  = format("%s%s", local.prefix, local.resource_suffixes.db_alb)
  sku   = local.zonal_deployment ? "Standard" : "Basic"

  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  frontend_ip_configuration {
    name                          = format("%s%s", local.prefix, local.resource_suffixes.db_alb_feip)
    subnet_id                     = local.sub_db_exists ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
    private_ip_address_allocation = "Static"
    private_ip_address = try(local.anydb.loadbalancer.frontend_ip,
      cidrhost(local.sub_db_exists ?
        data.azurerm_subnet.anydb[0].address_prefixes[0] :
        azurerm_subnet.anydb[0].address_prefixes[0],
      tonumber(count.index) + local.anydb_ip_offsets.anydb_lb)
    )
  }
}

resource "azurerm_lb_backend_address_pool" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.db_alb_bepool)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
}

resource "azurerm_lb_probe" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.db_alb_hp)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
  port                = local.loadbalancer_ports[0].port
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface_backend_address_pool_association" "anydb" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.anydb_db) : 0
  network_interface_id    = azurerm_network_interface.anydb_db[count.index].id
  ip_configuration_name   = azurerm_network_interface.anydb_db[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.anydb[0].id
}

# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "anydb" {
  count                        = local.enable_deployment ? max(length(local.zones), 1) : 0
  name                         = local.zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.zones[count.index], local.resource_suffixes.db_avset) : format("%s%s", local.prefix, local.resource_suffixes.db_avset)
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % length(local.zones)].id : var.ppg[0].id
  managed                      = true
}

# VNET ================================================================================================

# Creates db subnet of SAP VNET
resource "azurerm_subnet" "anydb" {
  count                = local.enable_deployment ? (local.sub_db_exists ? 0 : 1) : 0
  name                 = local.sub_db_name
  resource_group_name  = local.vnet_resource_group_name
  virtual_network_name = local.vnet_sap_name
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
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
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
