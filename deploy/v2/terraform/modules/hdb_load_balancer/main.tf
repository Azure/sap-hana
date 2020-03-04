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
