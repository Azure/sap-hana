# LOAD BALANCER ===================================================================================================

/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "lb" {
  count               = local.enable_deployment ? (local.vm_count > 1 ? 1 : 0) : 0
  name                = format("%s-%s-lb", var.role, local.prefix)
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name = format("%s-%s-lb-feip", var.role, local.prefix)

    subnet_id          = var.infrastructure.vnets.sap.subnet_db.is_existing ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
    private_ip_address = var.infrastructure.vnets.sap.subnet_db.is_existing ? try(local.any-databases.loadbalancer.frontend_ip, cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, tonumber(count.index) + 4)) : cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, tonumber(count.index) + 4)
  }
  sku = "Standard"

}

resource "azurerm_lb_backend_address_pool" "lb-back-pool" {
  count               = local.enable_deployment ? (local.vm_count > 1 ? 1 : 0) : 0
  name                = format("%s-%s-lb-bep", var.role, local.prefix)
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.lb[0].id

}

resource "azurerm_lb_probe" "lb-health-probe" {
  count               = local.enable_deployment ? (local.vm_count > 1 ? 1 : 0) : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.lb[0].id
  name                = format("%s-%s-lb-hpp", var.role, local.prefix)
  port                = (local.anydb_platform == "DB2") ? "62500" : "1521"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface_backend_address_pool_association" "lb-nic-bep" {
  count                   = local.enable_deployment ? (local.vm_count > 1 ? 1 : 0) : 0
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb-back-pool[0].id
}

resource "azurerm_lb_rule" "lb-rules" {
  count                          = local.enable_deployment ? (local.vm_count > 1 ? 1 : 0) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.lb[0].id
  name                           = "anydb_${local.loadbalancers[0].sid}_${local.loadbalancers[0].ports[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.loadbalancers[0].ports[count.index]
  backend_port                   = local.loadbalancers[0].ports[count.index]
  frontend_ip_configuration_name = format("%s-%s-lb-feip", var.role, local.prefix)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb-back-pool[0].id
  probe_id                       = azurerm_lb_probe.lb-health-probe[0].id
  enable_floating_ip             = true
}
