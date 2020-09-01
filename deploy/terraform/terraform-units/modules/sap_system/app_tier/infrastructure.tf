# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-app" {
  count                = local.enable_deployment ? (local.sub_app_exists ? 0 : 1) : 0
  name                 = local.sub_app_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.sub_app_prefix]
}

# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet-sap-app" {
  count                = local.enable_deployment ? (local.sub_app_exists ? 1 : 0) : 0
  name                 = split("/", local.sub_app_arm_id)[10]
  resource_group_name  = split("/", local.sub_app_arm_id)[4]
  virtual_network_name = split("/", local.sub_app_arm_id)[8]
}

# Creates web dispatcher subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-web" {
  count                = local.enable_deployment && local.sub_web_defined ? (local.sub_web_exists ? 0 : 1) : 0
  name                 = local.sub_web_name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [local.sub_web_prefix]
}

# Imports data of existing SAP web dispatcher subnet
data "azurerm_subnet" "subnet-sap-web" {
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
  name                = "${upper(local.application_sid)}_scs-alb"
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name                          = "${upper(local.application_sid)}_scs-feip"
    subnet_id                     = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.sub_app_exists ? local.scs_lb_ips[0] : cidrhost(local.sub_app_prefix, 0 + local.ip_offsets.scs_lb)
  }

  frontend_ip_configuration {
    name                          = "${upper(local.application_sid)}_ers-feip"
    subnet_id                     = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.sub_app_exists ? local.scs_lb_ips[1] : cidrhost(local.sub_app_prefix, 1 + local.ip_offsets.scs_lb)
  }
}

resource "azurerm_lb_backend_address_pool" "scs" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = "${upper(local.application_sid)}_scsAlb-bePool"
}

resource "azurerm_lb_probe" "scs" {
  count               = local.enable_deployment ? (local.scs_high_availability ? 2 : 1) : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = "${upper(local.application_sid)}_${count.index == 0 ? "scs" : "ers"}Alb-hp"
  port                = local.hp-ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create the SCS Load Balancer Rules
resource "azurerm_lb_rule" "scs" {
  count                          = local.enable_deployment ? length(local.lb-ports.scs) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = "${upper(local.application_sid)}_SCS_${local.lb-ports.scs[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.scs[count.index]
  backend_port                   = local.lb-ports.scs[count.index]
  frontend_ip_configuration_name = "${upper(local.application_sid)}_scs-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[0].id
  enable_floating_ip             = true
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers" {
  count                          = local.enable_deployment ? (local.scs_high_availability ? length(local.lb-ports.ers) : 0) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = "${upper(local.application_sid)}_ERS_${local.lb-ports.ers[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.ers[count.index]
  backend_port                   = local.lb-ports.ers[count.index]
  frontend_ip_configuration_name = "${upper(local.application_sid)}_ers-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[1].id
  enable_floating_ip             = true
}

# Create the SCS Availability Set
resource "azurerm_availability_set" "scs" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "${upper(local.application_sid)}_scs-avset"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}

/*
 Application Availability Set
*/

# Create the Application Availability Set
resource "azurerm_availability_set" "app" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "${upper(local.application_sid)}_app-avset"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}

/*
 Web dispatcher Load Balancer
 Web dispatcher Availability Set
*/

# Create the Web dispatcher Load Balancer
resource "azurerm_lb" "web" {
  count               = local.enable_deployment ? 1 : 0
  name                = "${upper(local.application_sid)}_web-alb"
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name                          = "sap${lower(local.application_sid)}web"
    subnet_id                     = local.sub_web_deployed.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.sub_web_defined ? cidrhost(local.sub_web_prefix, local.ip_offsets.web_lb) : cidrhost(local.sub_app_prefix, local.ip_offsets.web_lb)
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.web[0].id
  name                = "${upper(local.application_sid)}_webAlb-bePool"
}

//TODO: azurerm_lb_probe

# Create the Web dispatcher Load Balancer Rules
resource "azurerm_lb_rule" "web" {
  count                          = local.enable_deployment ? length(local.lb-ports.web) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.web[0].id
  name                           = "${upper(local.application_sid)}_webAlb-inRule${format("%02d", count.index)}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.web[count.index]
  backend_port                   = local.lb-ports.web[count.index]
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
  count                        = local.enable_deployment ? 1 : 0
  name                         = "${upper(local.application_sid)}_web-avset"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}
