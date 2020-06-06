# Create SCS NICs
resource "azurerm_network_interface" "nics-scs" {
  count                         = local.enable_deployment ? (var.application.scs_high_availability ? 2 : 1) : 0
  name                          = "scs${count.index}-${var.application.sid}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "scs${count.index}-${var.application.sid}-nic-ip"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = "10.1.3.1${count.index}"
    private_ip_address_allocation = "static"
  }
}

# Create the SCS Load Balancer
resource "azurerm_lb" "scs-lb" {
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
      private_ip_address            = "10.1.3.${5 + frontend_ip_configuration.value}"
    }
  }
}

resource "azurerm_lb_backend_address_pool" "scs-lb-back-pool" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs-lb[0].id
  name                = "scs-${var.application.sid}-lb-bep"
}

resource "azurerm_lb_probe" "scs-lb-health-probe" {
  count               = local.enable_deployment ? (var.application.scs_high_availability ? 2 : 1) : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.scs-lb[0].id
  name                = "${count.index == 0 ? "scs" : "ers"}-${var.application.sid}-lb-hp"
  port                = local.hp-ports[count.index]
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create the SCS Load Balancer Rules
resource "azurerm_lb_rule" "scs-lb-rules" {
  count                          = local.enable_deployment ? length(local.lb-ports.scs) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.scs-lb[0].id
  name                           = "SCS_${var.application.sid}_${local.lb-ports.scs[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.scs[count.index]
  backend_port                   = local.lb-ports.scs[count.index]
  frontend_ip_configuration_name = "scs-${var.application.sid}-lb-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs-lb-back-pool[0].id
  probe_id                       = azurerm_lb_probe.scs-lb-health-probe[0].id
  enable_floating_ip             = true
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers-lb-rules" {
  count                          = local.enable_deployment ? (var.application.scs_high_availability ? length(local.lb-ports.ers) : 0) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.scs-lb[0].id
  name                           = "ERS_${var.application.sid}_${local.lb-ports.ers[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = local.lb-ports.ers[count.index]
  backend_port                   = local.lb-ports.ers[count.index]
  frontend_ip_configuration_name = "ers-${var.application.sid}-lb-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.scs-lb-back-pool[0].id
  probe_id                       = azurerm_lb_probe.scs-lb-health-probe[1].id
  enable_floating_ip             = true
}

# Associate SCS VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "scs-lb-nic-bep" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.nics-scs) : 0
  network_interface_id    = azurerm_network_interface.nics-scs[count.index].id
  ip_configuration_name   = azurerm_network_interface.nics-scs[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.scs-lb-back-pool[0].id
}

# Create the SCS Availability Set
resource "azurerm_availability_set" "scs-as" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "scs-${var.application.sid}-as"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  managed                      = true
}

# Create the SCS VM(s)
resource "azurerm_linux_virtual_machine" "vm-scs" {
  count               = local.enable_deployment ? (var.application.scs_high_availability ? 2 : 1) : 0
  name                = "scs${count.index}-${var.application.sid}-vm"
  computer_name       = "${lower(var.application.sid)}scs${format("%02d", count.index)}"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  availability_set_id = azurerm_availability_set.scs-as[0].id
  network_interface_ids = [
    azurerm_network_interface.nics-scs[count.index].id
  ]
  size                            = "Standard_D8s_v3"
  admin_username                  = "scsadmin"
  admin_password                  = "password"
  disable_password_authentication = true

  os_disk {
    name                 = "scs${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "suse"
    offer     = "sles-sap-12-sp5"
    sku       = "gen1"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "scsadmin"
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}
