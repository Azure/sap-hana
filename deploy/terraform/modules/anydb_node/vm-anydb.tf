#############################################################################
# RESOURCES
#############################################################################

resource azurerm_network_interface "anydb" {
  count               = local.enable_deployment ? length(local.dbnodes) : 0
  name                = format("%s_xdb_%02d-nic", local.anydb_sid, (count.index))
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name

  ip_configuration {
    primary                       = true
    name                          = "${local.dbnodes[count.index].name}-db-nic-ip"
    subnet_id                     = local.sub_db_exists ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
    private_ip_address            = local.sub_db_exists ? local.dbnodes[count.index].db_nic_ip : lookup(local.dbnodes[count.index], "db_nic_ip", false) != false ? local.dbnodes[count.index].db_nic_ip : cidrhost(local.sub_db_prefix, tonumber(count.index) + 10)
    private_ip_address_allocation = "static"
  }
}

# Section for Linux Virtual machine 
resource azurerm_linux_virtual_machine "dbserver" {
  count                        = local.enable_deployment ? ((upper(local.anydb_ostype) == "LINUX") ? length(local.dbnodes) : 0) : 0
  name                         = local.dbnodes[count.index].name
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.anydb[0].id
  proximity_placement_group_id = local.ppgId
  network_interface_ids        = [azurerm_network_interface.anydb[count.index].id]
  size                         = local.dbnodes.size

  source_image_id = local.anydb_custom_image ? local.anydb_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.anydb_custom_image ? 0 : 1)
    content {
      publisher = local.anydb_os.publisher
      offer     = local.anydb_os.offer
      sku       = local.anydb_os.sku
      version   = local.anydb_os.version
    }
  }

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.anydb_size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
<<<<<<< HEAD
      name                 = format("%s_xdb%02d-OsDisk", upper(local.anydb_sid), (count.index))
=======
      name                 = format("%s-OsDisk", local.dbnodes[count.index].name)
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

<<<<<<< HEAD
  computer_name                   = "${local.anydb_sid}dlwm${count.index}"
=======
  computer_name                   = "${local.anydb_sid}dbl${count.index}"
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
  admin_username                  = local.authentication.username
  disable_password_authentication = local.authentication.type != "password" ? true : false

  admin_ssh_key {
    username   = local.authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
<<<<<<< HEAD
    role        = "db"
=======
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
    SID         = local.anydb_sid
  }
}

# Section for Windows Virtual machine based on a marketplace image 
resource azurerm_windows_virtual_machine "dbserver" {
  count                        = local.enable_deployment ? ((upper(local.anydb_ostype) == "WINDOWS") ? length(local.dbnodes) : 0) : 0
<<<<<<< HEAD
  name                         = format("db%02d-%s-vmw", (count.index + 1), local.anydb_sid)
=======
  name                         = local.dbnodes[count.index].name
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.anydb[0].id
  proximity_placement_group_id = local.ppgId
  network_interface_ids        = [azurerm_network_interface.anydb[count.index].id]
<<<<<<< HEAD
  size                         = local.sku
=======
  size                         = try(lookup(local.sizes, local.anydb_size).compute.vm_size, "Standard_E4s_v3")
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc

  source_image_id = local.anydb_custom_image ? local.anydb_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.anydb_custom_image ? 0 : 1)
    content {
      publisher = local.anydb_os.publisher
      offer     = local.anydb_os.offer
      sku       = local.anydb_os.sku
      version   = local.anydb_os.version
    }
  }

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.anydb_size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
<<<<<<< HEAD
      name                 = format("db%02d-%s-vm-osdisk", (count.index + 1), local.anydb_sid)
=======
      name                 = format("%s-OsDisk", local.dbnodes[count.index].name)
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

<<<<<<< HEAD
  computer_name  = "${local.anydb_sid}dbwm${count.index}"
=======
  computer_name  = "${local.anydb_sid}dbl${count.index}"
>>>>>>> 9bc9f51b04fd03058725955a864a83ffe5446fbc
  admin_username = local.authentication.username
  admin_password = local.authentication.password

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
    role        = "db"
    SID         = upper(local.anydb_sid)
  }
}

# Creates managed data disks
resource azurerm_managed_disk "disks" {
  count                = local.enable_deployment ? length(local.anydb_disks) : 0
  name                 = local.anydb_disks[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.anydb_disks[count.index].storage_account_type
  disk_size_gb         = local.anydb_disks[count.index].disk_size_gb
}

# Manages attaching a Disk to a Virtual Machine
resource azurerm_virtual_machine_data_disk_attachment "vm-disks" {
  count                     = local.enable_deployment ? length(azurerm_managed_disk.disks) : 0
  managed_disk_id           = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id        = upper(local.anydb_ostype) == "LINUX" ? azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id : azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id
  caching                   = local.anydb_disks[count.index].caching
  write_accelerator_enabled = local.anydb_disks[count.index].write_accelerator_enabled
  lun                       = count.index
}
