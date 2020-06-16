# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-app" {
  count                = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.is_existing ? 0 : 1) : 0
  name                 = var.infrastructure.vnets.sap.subnet_app.name
  resource_group_name  = var.vnet-sap[0].resource_group_name
  virtual_network_name = var.vnet-sap[0].name
  address_prefixes     = [var.infrastructure.vnets.sap.subnet_app.prefix]
}

# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet-sap-app" {
  count                = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.is_existing ? 1 : 0) : 0
  name                 = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[10]
  resource_group_name  = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[4]
  virtual_network_name = split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[8]
}

# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1) : 0
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 1 : 0) : 0
  name                = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[4]
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-app" {
  count                     = local.enable_deployment ? (signum((var.infrastructure.vnets.sap.subnet_app.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? 0 : 1))) : 0
  subnet_id                 = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}

# Create the SCS Load Balancer
resource "azurerm_lb" "scs" {
  count               = local.enable_deployment ? 1 : 0
  name                = "scs-${var.application.sid}-lb"
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  dynamic "frontend_ip_configuration" {
    for_each = range(var.application.scs_high_availability ? 2 : 1)
    content {
      name                          = "${frontend_ip_configuration.value == 0 ? "scs" : "ers"}-${var.application.sid}-lb-feip"
      subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
      private_ip_address_allocation = "Static"
      private_ip_address            = cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, tonumber(frontend_ip_configuration.value) + local.ip_offsets.scs_lb)
    }
  }
}

resource "azurerm_lb_backend_address_pool" "scs" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = "scs-${var.application.sid}-lb-bep"
}

resource "azurerm_lb_probe" "scs" {
  count               = local.enable_deployment ? (var.application.scs_high_availability ? 2 : 1) : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs[0].id
  name                = "${count.index == 0 ? "scs" : "ers"}-${var.application.sid}-lb-hp"
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
  name                           = "SCS_${var.application.sid}_${local.lb-ports.scs[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.scs[count.index]
  backend_port                   = local.lb-ports.scs[count.index]
  frontend_ip_configuration_name = "scs-${var.application.sid}-lb-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[0].id
  enable_floating_ip             = true
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers" {
  count                          = local.enable_deployment ? (var.application.scs_high_availability ? length(local.lb-ports.ers) : 0) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.scs[0].id
  name                           = "ERS_${var.application.sid}_${local.lb-ports.ers[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.ers[count.index]
  backend_port                   = local.lb-ports.ers[count.index]
  frontend_ip_configuration_name = "ers-${var.application.sid}-lb-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs[0].id
  probe_id                       = azurerm_lb_probe.scs[1].id
  enable_floating_ip             = true
}
