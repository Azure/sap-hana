# LOAD BALANCER ===================================================================================================

/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "anydb-lb" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s-%s-lb", local.prefix, var.role)
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name = format("%s-%s-lb-feip", local.prefix, var.role)

    subnet_id                     = var.infrastructure.vnets.sap.subnet_db.is_existing ? data.azurerm_subnet.subnet-anydb[0].id : azurerm_subnet.subnet-anydb[0].id
    private_ip_address_allocation = "Dynamic"
  }
  sku = "Standard"

}

resource "azurerm_lb_backend_address_pool" "anydb-lb-back-pool" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s-%s-lb-bep", local.prefix, var.role)
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.anydb-lb[0].id

}

resource "azurerm_lb_probe" "anydb-lb-health-probe" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.anydb-lb[0].id
  name                = format("%s-%s-lb-hpp", local.prefix, var.role)
  port                = (local.dbplatform== "DB2") ? "62500" : "1521"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# TODO:
# Current behavior, it will try to add all VMs in the cluster into the backend pool, which would not work since we do not have availability sets created yet.
# In a scale-out scenario, we need to rewrite this code according to the scale-out + HA reference architecture.
resource "azurerm_network_interface_backend_address_pool_association" "anydb-lb-nic-bep" {
  count               = local.enable_deployment ? 1 : 0
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.anydb-lb-back-pool[0].id
}

# resource "azurerm_lb_rule" "anydb-lb-rules" {
#   count                          = length(local.loadbalancers-ports)
#   resource_group_name            = var.resource-group[0].name
#   loadbalancer_id                = azurerm_lb.anydb-lb[0].id
#   name                           = "anydb_${local.loadbalancers[0].sid}_${local.loadbalancers[0].ports[count.index]}"
#   protocol                       = "Tcp"
#   frontend_port                  = local.loadbalancers[0].ports[count.index]
#   backend_port                   = local.loadbalancers[0].ports[count.index]
#   frontend_ip_configuration_name = "anydb-${local.loadbalancers[0].sid}-lb-feip"
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.anydb-lb-back-pool[0].id
#   probe_id                       = azurerm_lb_probe.anydb-lb-health-probe[0].id
#   enable_floating_ip             = true
# }
