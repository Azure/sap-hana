/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "anydb" {
  count = local.enable_deployment ? 1 : 0
  name  = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb)
  sku   = "Standard"

  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  frontend_ip_configuration {
    name      = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_feip)
    subnet_id = var.db_subnet.id

    private_ip_address = local.use_DHCP ? (
      null) : (
      try(local.anydb.loadbalancer.frontend_ip,
        cidrhost(var.db_subnet.address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.anydb_lb)
      )
    )
    private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_bepool)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
}

resource "azurerm_lb_probe" "anydb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_hp)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.anydb[count.index].id
  port                = local.loadbalancer_ports[0].port
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "anydb" {
  count                          = local.enable_deployment ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.anydb[0].id
  name                           = format("%s%s%s%05d-%02d", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_rule, 0, count.index)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.anydb[0].id
  probe_id                       = azurerm_lb_probe.anydb[0].id
  enable_floating_ip             = true
}


resource "azurerm_network_interface_backend_address_pool_association" "anydb" {
  count                   = local.enable_deployment ? local.db_server_count : 0
  network_interface_id    = azurerm_network_interface.anydb_db[count.index].id
  ip_configuration_name   = azurerm_network_interface.anydb_db[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.anydb[0].id
}

# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "anydb" {
  count = local.enable_deployment && ! local.availabilitysets_exist ? max(length(local.zones), 1) : 0
  name = local.zonal_deployment ? (
    format("%s%sz%s%s%s", local.prefix, var.naming.separator, local.zones[count.index], var.naming.separator, local.resource_suffixes.db_avset)) : (
    format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_avset)
  )
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % length(local.zones)].id : var.ppg[0].id
  managed                      = true
}

data "azurerm_availability_set" "anydb" {
  count               = local.enable_deployment && local.availabilitysets_exist ? max(length(local.zones), 1) : 0
  name                = split("/", local.availabilityset_arm_ids[count.index])[8]
  resource_group_name = split("/", local.availabilityset_arm_ids[count.index])[4]
}

