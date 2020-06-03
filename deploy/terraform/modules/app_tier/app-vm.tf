# Create Application NICs
resource "azurerm_network_interface" "nics-app" {
  count                         = 2
  name                          = "app${count.index}-${local.sid}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "app${count.index}-${local.sid}-nic-ip"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = "10.1.3.2${count.index}"
    private_ip_address_allocation = "static"
  }
}

# Associate Application NICs with the Network Security Group
resource "azurerm_network_interface_security_group_association" "nic-app-nsg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nics-app[count.index].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}


# Create the Application Availability Set
resource "azurerm_availability_set" "app-as" {
  count                        = 1
  name                         = "app-${local.sid}-as"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  managed                      = true
}

# Create the Application VM(s)
resource "azurerm_linux_virtual_machine" "vm-app" {
  count               = 2
  name                = "app${count.index}-${local.sid}-vm"
  computer_name       = "${lower(local.sid)}app${format("%02d", count.index)}"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  availability_set_id = azurerm_availability_set.app-as[0].id
  network_interface_ids = [
    azurerm_network_interface.nics-app[count.index].id
  ]
  size                            = "Standard_D8s_v3"
  admin_username                  = "appadmin"
  admin_password                  = "password"
  disable_password_authentication = true

  os_disk {
    name                 = "app${count.index}-osdisk"
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
    username   = "appadmin"
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# TODO: Disk(s) ?
# Do we need additional data disk?


# TODO: Disk Attachment ?
