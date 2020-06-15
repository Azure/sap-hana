# Create Application NICs
resource "azurerm_network_interface" "nics-app" {
  count                         = local.enable_deployment ? var.application.application_server_count : 0
  name                          = "app${count.index}-${var.application.sid}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.app_nic_accelerated_networking

  ip_configuration {
    name                          = "app${count.index}-${var.application.sid}-nic-ip"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, tonumber(count.index) + local.ip_offsets.app_vm)
    private_ip_address_allocation = "static"
  }
}

# Create the Application Availability Set
resource "azurerm_availability_set" "app-as" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "app-${var.application.sid}-as"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}

# Create the Application VM(s)
resource "azurerm_linux_virtual_machine" "vm-app" {
  count                        = local.enable_deployment ? var.application.application_server_count : 0
  name                         = "app${count.index}-${var.application.sid}-vm"
  computer_name                = "${lower(var.application.sid)}app${format("%02d", count.index)}"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.app-as[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids        = [
    azurerm_network_interface.nics-app[count.index].id
  ]
  size                            = local.app_vm_size
  admin_username                  = var.application.authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = "app${count.index}-osdisk"
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
