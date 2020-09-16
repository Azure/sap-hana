# Create SCS NICs
resource "azurerm_network_interface" "scs" {
  count                         = local.enable_deployment ? (local.scs_high_availability ? 2 : 1) : 0
  name                          = format("%s_%s-scs-nic", local.prefix, format("%sscs%02d%s%s", lower(local.sid), count.index, upper(local.app_ostype) == "LINUX" ? "l": "w", substr(var.random-id.hex,0,3)))
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.scs_sizing.compute.accelerated_networking

  ip_configuration {
    name                          = "IPConfig1"
    subnet_id                     = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = try(local.scs_nic_ips [count.index],cidrhost(local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].address_prefixes[0] : azurerm_subnet.subnet-sap-app[0].address_prefixes[0], tonumber(count.index) + local.ip_offsets.scs_vm))
    private_ip_address_allocation = "static"
  }
}

# Associate SCS VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "scs" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.scs) : 0
  network_interface_id    = azurerm_network_interface.scs[count.index].id
  ip_configuration_name   = azurerm_network_interface.scs[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.scs[0].id
}

# Create the SCS Linux VM(s)
resource "azurerm_linux_virtual_machine" "scs" {
  count                        = local.enable_deployment ? (upper(local.app_ostype) == "LINUX" ? (local.scs_high_availability ? 2 : 1) : 0) : 0
  name                         = format("%s_%s",  local.prefix, format("%sscs%02dl%s", lower(local.sid), count.index, substr(var.random-id.hex,0,3)))
  computer_name                = format("%sscs%02dl%s", lower(local.sid), count.index, substr(var.random-id.hex,0,3))
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.scs[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.scs[count.index].id
  ]
  size                            = local.scs_sizing.compute.vm_size
  admin_username                  = local.sid_auth_username
  disable_password_authentication = ! local.enable_auth_password
  admin_password                  = local.sid_auth_password

  os_disk {
    name                 = format("%s_%sscs%02dl%s-osdisk", local.prefix, lower(local.sid), count.index, substr(var.random-id.hex,0,3))
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  dynamic "admin_ssh_key" {
    for_each = range(local.enable_auth_password ? 0 : 1)
    content {
      username   = local.sid_auth_username
      public_key = file(var.sshkey.path_to_public_key)
    }
  }
  
  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Create the SCS Windows VM(s)
resource "azurerm_windows_virtual_machine" "scs" {
  count                        = local.enable_deployment ? (upper(local.app_ostype) == "WINDOWS" ? (local.scs_high_availability ? 2 : 1) : 0) : 0
  name                         = format("%s_%s",  local.prefix, format("%sscs%02dw%s", lower(local.sid), count.index, substr(var.random-id.hex,0,3)))
  computer_name                = format("%sscs%02dw%s", lower(local.sid), count.index, substr(var.random-id.hex,0,3))
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.scs[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.scs[count.index].id
  ]
  size           = local.scs_sizing.compute.vm_size
  admin_username = local.sid_auth_username
  admin_password = local.sid_auth_password

  os_disk {
    name                 = format("%s_%sscs%02dw%s", local.prefix, lower(local.sid), count.index, substr(var.random-id.hex,0,3))
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Creates managed data disk
resource "azurerm_managed_disk" "scs" {
  count                = local.enable_deployment ? length(local.scs-data-disks) : 0
  name                 = format("%s_%s%s", local.prefix, format("%sscs%02d%s%s", lower(local.sid), count.index, upper(local.app_ostype) == "LINUX" ? "l": "w", substr(var.random-id.hex,0,3)),local.scs-data-disks[count.index].suffix)
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.scs-data-disks[count.index].disk_type
  disk_size_gb         = local.scs-data-disks[count.index].size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "scs" {
  count                     = local.enable_deployment ? length(azurerm_managed_disk.scs) : 0
  managed_disk_id           = azurerm_managed_disk.scs[count.index].id
  virtual_machine_id        = upper(local.app_ostype) == "LINUX" ? azurerm_linux_virtual_machine.scs[local.scs-data-disks[count.index].vm_index].id : azurerm_windows_virtual_machine.scs[local.scs-data-disks[count.index].vm_index].id
  caching                   = local.scs-data-disks[count.index].caching
  write_accelerator_enabled = local.scs-data-disks[count.index].write_accelerator
  lun                       = count.index
}
