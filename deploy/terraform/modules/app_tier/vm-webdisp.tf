# Create Web dispatcher NICs
resource "azurerm_network_interface" "web" {
  count                         = local.enable_deployment ? local.webdispatcher_count : 0
  name                          = "${upper(local.application_sid)}_web${format("%02d", count.index)}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.web_sizing.compute.accelerated_networking

  ip_configuration {
    name                          = "IPConfig1"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, tonumber(count.index) + local.ip_offsets.web_vm)
    private_ip_address_allocation = "static"
  }
}

# Create the Web dispatcher VM(s)
resource "azurerm_linux_virtual_machine" "web" {
  count                        = local.enable_deployment ? local.webdispatcher_count : 0
  name                         = "${upper(local.application_sid)}_web${format("%02d", count.index)}"
  computer_name                = "${upper(local.application_sid)}web${format("%02d", count.index)}"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.web[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]
  size                            = local.web_sizing.compute.vm_size
  admin_username                  = local.authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = "${upper(local.application_sid)}_web${format("%02d", count.index)}-osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.os.publisher
    offer     = local.os.offer
    sku       = local.os.sku
    version   = local.os.version
  }

  admin_ssh_key {
    username   = local.authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}
