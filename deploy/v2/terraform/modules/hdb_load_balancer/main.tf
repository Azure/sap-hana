# Use Azure SAP naming conventions for HANA resources
module "hana_resource_names" {
  source = "../azure_sap_naming_conventions"
  name   = "hdb"
}

resource "azurerm_lb" "hana-lb" {
  name                = module.hana_resource_names.lb
  resource_group_name = var.resource_group_name
  location            = var.location

  frontend_ip_configuration {
    name                          = module.hana_resource_names.lb_fe_ip_conf
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_ip
  }
}

resource "azurerm_lb_backend_address_pool" "hana-lb-back-pool" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.hana-lb.id
  name                = module.hana_resource_names.lb_be_pool
}

resource "azurerm_lb_probe" "hana-lb-health-probe" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.hana-lb.id
  name                = module.hana_resource_names.lb_health_probe
  port                = "625${var.instance_number}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface_backend_address_pool_association" "hana-lb-nic-bep" {
  count                   = length(var.network_interfaces)
  network_interface_id    = var.network_interfaces[count.index].id
  ip_configuration_name   = var.network_interfaces[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.hana-lb-back-pool.id
}
