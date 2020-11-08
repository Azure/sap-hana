
# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet_sap_app" {
  count                = local.enable_deployment ? (local.sub_app_exists ? 0 : 1) : 0
  name                 = local.sub_app_name
  resource_group_name  = local.vnet_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_app_prefix]
}

# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet_sap_app" {
  count                = local.enable_deployment ? (local.sub_app_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_app_arm_id)[10]
  resource_group_name  = split("/", local.sub_app_arm_id)[4]
  virtual_network_name = split("/", local.sub_app_arm_id)[8]
}

# Creates web dispatcher subnet of SAP VNET
resource "azurerm_subnet" "subnet_sap_web" {
  count                = local.enable_deployment && local.sub_web_defined ? (local.sub_web_exists ? 0 : 1) : 0
  name                 = local.sub_web_name
  resource_group_name  = local.vnet_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_web_prefix]
}

# Imports data of existing SAP web dispatcher subnet
data "azurerm_subnet" "subnet_sap_web" {
  count                = local.enable_deployment && local.sub_web_defined ? (local.sub_web_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_web_arm_id)[10]
  resource_group_name  = split("/", local.sub_web_arm_id)[4]
  virtual_network_name = split("/", local.sub_web_arm_id)[8]
}

/*
 SCS Load Balancer
 SCS Availability Set
*/

# Create the SCS Load Balancer
resource "azurerm_lb" "scs" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.scs_alb)
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  sku                 = local.scs_zonal_deployment ? "Standard" : "Basic"

  frontend_ip_configuration {
    name                          = format("%s%s", local.prefix, local.resource_suffixes.scs_alb_feip)
    subnet_id                     = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = try(local.scs_lb_ips[0], cidrhost(local.sub_app_prefix, 0 + local.ip_offsets.scs_lb))
  }

  frontend_ip_configuration {
    name                          = format("%s%s", local.prefix, local.resource_suffixes.scs_ers_feip)
    subnet_id                     = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = try(local.scs_lb_ips[1], cidrhost(local.sub_app_prefix, 1 + local.ip_offsets.scs_lb))
  }
}

resource "azurerm_lb_backend_address_pool" "scs" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.scs_alb_bepool)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id

}

resource "azurerm_lb_probe" "scs" {
  count               = local.enable_deployment ? (local.scs_high_availability ? 2 : 1) : 0
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = format("%s%s", local.prefix, local.resource_suffixes[count.index == 0 ? "scs_alb_hp" : "scs_ers_hp"])
  port                = local.hp_ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create the SCS Load Balancer Rules
resource "azurerm_lb_rule" "scs" {
  count                          = local.enable_deployment ? length(local.lb_ports.scs) : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%05d-%02d", local.prefix, local.resource_suffixes.scs_scs_rule, local.lb_ports.scs[count.index], count.index)
  protocol                       = "Tcp"
  frontend_port                  = local.lb_ports.scs[count.index]
  backend_port                   = local.lb_ports.scs[count.index]
  frontend_ip_configuration_name = format("%s%s", local.prefix, local.resource_suffixes.scs_alb_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[0].id
  enable_floating_ip             = true
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers" {
  count                          = local.enable_deployment ? (local.scs_high_availability ? length(local.lb_ports.ers) : 0) : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%05d-%02d", local.prefix, local.resource_suffixes.scs_ers_rule, local.lb_ports.ers[count.index], count.index)
  protocol                       = "Tcp"
  frontend_port                  = local.lb_ports.ers[count.index]
  backend_port                   = local.lb_ports.ers[count.index]
  frontend_ip_configuration_name = format("%s%s", local.prefix, local.resource_suffixes.scs_ers_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[1].id
  enable_floating_ip             = true
}

# Create the SCS Availability Set
resource "azurerm_availability_set" "scs" {
  count                        = local.enable_deployment ? local.scs_server_count == local.scs_zone_count ? 0 : max(length(local.scs_zones), 1) : 0
  name                         = local.scs_zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.scs_zones[count.index], local.resource_suffixes.scs_avset) : format("%s%s", local.prefix, local.resource_suffixes.scs_avset)
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.scs_zonal_deployment ? var.ppg[count.index % length(local.scs_zones)].id : var.ppg[0].id
  managed                      = true
}

/*
 Application Availability Set
*/

# Create the Application Availability Set
resource "azurerm_availability_set" "app" {
  count                        = local.enable_deployment ? local.application_server_count == local.app_zone_count ? 0 : max(local.app_zone_count, 1) : 0
  name                         = local.app_zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.app_zones[count.index], local.resource_suffixes.app_avset) : format("%s%s", local.prefix, local.resource_suffixes.app_avset)
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.app_zonal_deployment ? var.ppg[count.index % local.app_zone_count].id : var.ppg[0].id
  managed                      = true
}

/*
 Web dispatcher Load Balancer
 Web dispatcher Availability Set
*/

# Create the Web dispatcher Load Balancer
resource "azurerm_lb" "web" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.web_alb)
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  sku                 = local.web_zonal_deployment ? "Standard" : "Basic"

  frontend_ip_configuration {
    name                          = format("%s%s", local.prefix, local.resource_suffixes.web_alb_feip)
    subnet_id                     = local.sub_web_deployed.id
    private_ip_address            = try(local.web_lb_ips[0], cidrhost(local.sub_web_deployed.address_prefixes[0], local.ip_offsets.web_lb))
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.web_alb_bepool)
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.web[0].id
}

//TODO: azurerm_lb_probe

# Create the Web dispatcher Load Balancer Rules
resource "azurerm_lb_rule" "web" {
  count                          = local.enable_deployment ? length(local.lb_ports.web) : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.web[0].id
  name                           = format("%s%s%05d-%02d", local.prefix, local.resource_suffixes.web_alb_inrule, local.lb_ports.web[count.index], count.index)
  protocol                       = "Tcp"
  frontend_port                  = local.lb_ports.web[count.index]
  backend_port                   = local.lb_ports.web[count.index]
  frontend_ip_configuration_name = azurerm_lb.web[0].frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web[0].id
  enable_floating_ip             = true
}

# Associate Web dispatcher VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.web) : 0
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = azurerm_network_interface.web[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web[0].id
}

# Create the Web dispatcher Availability Set
resource "azurerm_availability_set" "web" {
  count                        = local.enable_deployment ? local.webdispatcher_count == local.web_zone_count ? 0 : max(length(local.web_zones), 1) : 0
  name                         = local.web_zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.web_zones[count.index], local.resource_suffixes.web_avset) : format("%s%s", local.prefix, local.resource_suffixes.web_avset)
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.web_zonal_deployment ? var.ppg[count.index % length(local.web_zones)].id : var.ppg[0].id
  managed                      = true
}
