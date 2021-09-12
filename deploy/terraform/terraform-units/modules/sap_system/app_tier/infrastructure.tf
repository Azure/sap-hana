
# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet_sap_app" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (local.sub_app_exists ? 0 : 1) : 0
  name                 = local.sub_app_name
  resource_group_name  = local.vnet_sap_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_app_prefix]
}


# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet_sap_app" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (local.sub_app_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_app_arm_id)[10]
  resource_group_name  = split("/", local.sub_app_arm_id)[4]
  virtual_network_name = split("/", local.sub_app_arm_id)[8]
}

# Creates web dispatcher subnet of SAP VNET
resource "azurerm_subnet" "subnet_sap_web" {
  provider             = azurerm.main
  depends_on           = [azurerm_subnet.subnet_sap_app]
  count                = local.enable_deployment && local.sub_web_defined ? (local.sub_web_exists ? 0 : 1) : 0
  name                 = local.sub_web_name
  resource_group_name  = local.vnet_sap_resource_group_name
  virtual_network_name = local.vnet_sap_name
  address_prefixes     = [local.sub_web_prefix]
}

# Imports data of existing SAP web dispatcher subnet
data "azurerm_subnet" "subnet_sap_web" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (local.sub_web_exists ? 1 : 0) : 0
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
  provider            = azurerm.main
  count               = local.enable_scs_lb_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_alb)
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  sku                 = "Standard"

  dynamic "frontend_ip_configuration" {
    iterator = pub
    for_each = local.fpips
    content {
      name                          = pub.value.name
      subnet_id                     = pub.value.subnet_id
      private_ip_address            = pub.value.private_ip_address
      private_ip_address_allocation = pub.value.private_ip_address_allocation
    }

  }
}

resource "azurerm_lb_backend_address_pool" "scs" {
  provider        = azurerm.main
  count           = local.enable_scs_lb_deployment ? 1 : 0
  name            = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_alb_bepool)
  loadbalancer_id = azurerm_lb.scs[0].id

}

resource "azurerm_lb_probe" "scs" {
  provider            = azurerm.main
  count               = local.enable_scs_lb_deployment ? (local.scs_high_availability ? 2 : 1) : 0
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes[count.index == 0 ? "scs_alb_hp" : "scs_ers_hp"])
  port                = local.hp_ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "clst" {
  provider            = azurerm.main
  count               = local.enable_scs_lb_deployment && (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS") ? 1 : 0
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_clst_hp)
  port                = local.hp_ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "fs" {
  provider            = azurerm.main
  count               = local.enable_scs_lb_deployment && (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS") ? 1 : 0
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_fs_hp)
  port                = local.hp_ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}


# Create the SCS Load Balancer Rules
resource "azurerm_lb_rule" "scs" {
  provider                       = azurerm.main
  count                          = local.enable_scs_lb_deployment ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_scs_rule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_alb_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[0].id
  enable_floating_ip             = true
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers" {
  provider                       = azurerm.main
  count                          = local.enable_scs_lb_deployment && local.scs_high_availability ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_ers_rule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_ers_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[1].id
  enable_floating_ip             = true
}

resource "azurerm_lb_rule" "clst" {
  provider                       = azurerm.main
  count                          = local.enable_scs_lb_deployment && local.win_ha_scs ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_clst_rule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_clst_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.clst[0].id
  enable_floating_ip             = true
}

resource "azurerm_lb_rule" "fs" {
  provider                       = azurerm.main
  count                          = local.enable_scs_lb_deployment && local.win_ha_scs ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_fs_rule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_fs_feip)
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.fs[0].id
  enable_floating_ip             = true
}

# Create the SCS Availability Set
resource "azurerm_availability_set" "scs" {
  count                        = local.enable_deployment && local.use_scs_avset ? max(length(local.scs_zones), 1) : 0
  name                         = format("%s%s%s", local.prefix, var.naming.separator, var.naming.scs_avset_names[count.index])
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.scs_zonal_deployment ? var.ppg[count.index % length(local.scs_zones)].id : var.ppg[0].id
  managed                      = true
}

/*
 Application Availability Set
*/

# Create the Application Availability Set
resource "azurerm_availability_set" "app" {
  provider                     = azurerm.main
  count                        = local.enable_deployment && local.use_app_avset ? max(length(local.app_zones), 1) : 0
  name                         = format("%s%s%s", local.prefix, var.naming.separator, var.naming.app_avset_names[count.index])
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.app_zonal_deployment ? var.ppg[count.index % local.app_zone_count].id : var.ppg[0].id
  managed                      = true
}

/*
 Web dispatcher Load Balancer
 Web dispatcher Availability Set
*/

# Create the Web dispatcher Load Balancer
resource "azurerm_lb" "web" {
  provider            = azurerm.main
  count               = local.enable_web_lb_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb)
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb_feip)
    subnet_id = local.sub_web_deployed.id
    private_ip_address = var.application.use_DHCP ? (
      null) : (
      try(local.web_lb_ips[0], cidrhost(local.sub_web_deployed.address_prefixes[0], local.ip_offsets.web_lb))
    )
    private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  provider        = azurerm.main
  count           = local.enable_web_lb_deployment ? 1 : 0
  name            = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb_bepool)
  loadbalancer_id = azurerm_lb.web[0].id
}

//TODO: azurerm_lb_probe

# Create the Web dispatcher Load Balancer Rules
resource "azurerm_lb_rule" "web" {
  provider                       = azurerm.main
  count                          = local.enable_web_lb_deployment ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.web[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb_inrule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = azurerm_lb.web[0].frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web[0].id
  enable_floating_ip             = true
}

# Associate Web dispatcher VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  provider                = azurerm.main
  depends_on              = [azurerm_lb_backend_address_pool.web]
  count                   = local.enable_web_lb_deployment ? 1 : 0
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = azurerm_network_interface.web[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web[0].id
}

# Create the Web dispatcher Availability Set
resource "azurerm_availability_set" "web" {
  count                        = local.enable_deployment && local.use_web_avset ? max(length(local.web_zones), 1) : 0
  name                         = format("%s%s%s", local.prefix, var.naming.separator, var.naming.web_avset_names[count.index])
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.web_zonal_deployment ? var.ppg[count.index % length(local.web_zones)].id : var.ppg[0].id
  managed                      = true
}


//ASG

resource "azurerm_application_security_group" "app" {
  provider            = azurerm.main
  count               = local.enable_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_asg)
  resource_group_name = local.nsg_asg_with_vnet ? local.vnet_sap_resource_group_name : var.resource_group[0].name
  location            = local.nsg_asg_with_vnet ? local.vnet_sap_resource_group_location : var.resource_group[0].location
}

resource "azurerm_application_security_group" "web" {
  provider            = azurerm.main
  count               = local.webdispatcher_count > 0 ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_asg)
  resource_group_name = local.nsg_asg_with_vnet ? local.vnet_sap_resource_group_name : var.resource_group[0].name
  location            = local.nsg_asg_with_vnet ? local.vnet_sap_resource_group_location : var.resource_group[0].location
}

resource "azurerm_subnet_route_table_association" "subnet_sap_app" {
  depends_on     = [azurerm_network_interface.app]
  provider       = azurerm.main
  count          = !local.sub_app_exists && local.enable_deployment && length(var.route_table_id) > 0 ? 1 : 0
  subnet_id      = azurerm_subnet.subnet_sap_app[0].id
  route_table_id = var.route_table_id
}

resource "azurerm_subnet_route_table_association" "subnet_sap_web" {
  depends_on     = [azurerm_network_interface.web]
  provider       = azurerm.main
  count          = local.enable_deployment && local.enable_deployment && local.sub_web_defined && length(var.route_table_id) > 0 ? (local.sub_web_exists ? 0 : 1) : 0
  subnet_id      = azurerm_subnet.subnet_sap_web[0].id
  route_table_id = var.route_table_id
}
