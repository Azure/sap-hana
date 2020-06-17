# Create Web dispatcher NICs
resource "azurerm_network_interface" "web" {
  count                         = local.enable_deployment ? var.application.webdispatcher_count : 0
  name                          = "${upper(var.application.sid)}_web${format("%02d", count.index)}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.web_nic_accelerated_networking

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, tonumber(count.index) + local.ip_offsets.web_vm)
    private_ip_address_allocation = "static"
  }
}

# Create the Web dispatcher Availability Set
resource "azurerm_availability_set" "web" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "${upper(var.application.sid)}_web-avset"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}

# Create the Web dispatcher Load Balancer
resource "azurerm_lb" "web" {
  count               = local.enable_deployment ? 1 : 0
  name                = "${upper(var.application.sid)}_web-alb"
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name                          = "sap${lower(var.application.sid)}web"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, local.ip_offsets.web_lb)
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.web[0].id
  name                = "${upper(var.application.sid)}_webAlb-bePool"
}

//TODO: azurerm_lb_probe

# Create the Web dispatcher Load Balancer Rules
resource "azurerm_lb_rule" "web" {
  count                          = local.enable_deployment ? length(local.lb-ports.web) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.web[0].id
  name                           = "${upper(var.application.sid)}_webAlb-inRule${format("%02d", count.index)}"
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

# Create the Web dispatcher VM(s)
resource "azurerm_linux_virtual_machine" "web" {
  count                        = local.enable_deployment ? var.application.webdispatcher_count : 0
  name                         = "${upper(var.application.sid)}_web${format("%02d", count.index)}"
  computer_name                = "${upper(var.application.sid)}web${format("%02d", count.index)}"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.web[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]
  size                            = local.web_vm_size
  admin_username                  = var.application.authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = "${upper(var.application.sid)}_web${format("%02d", count.index)}-osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.os.publisher
    offer     = local.os.offer
    sku       = local.os.sku
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.application.authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}
