locals {
  os = {
    source_image_id = "/subscriptions/c4106f40-4f28-442e-b67f-a24d892bf7ad/resourceGroups/nancyc-image/providers/Microsoft.Compute/images/nancyc-ubuntu-20200706"
    #publisher = "Canonical"
    #offer     = "UbuntuServer"
    #sku       = "18.04-LTS"
    #version   = "latest"
  }

}



#############################################################################
# RESOURCES
#############################################################################


resource azurerm_network_interface "nic" {
  count               = local.enable_deployment ? local.vm_count : 0
  name                = format("%s%02d-%s-nic", var.role, (count.index + 1), local.prefix)
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name

  ip_configuration {
    primary                       = true
    name                          = "${local.dbnodes[count.index].name}-db-nic-ip"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_db.is_existing ? data.azurerm_subnet.anydb[0].id : azurerm_subnet.anydb[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_db.is_existing ? local.dbnodes[count.index].db_nic_ip : lookup(local.dbnodes[count.index], "db_nic_ip", false) != false ? local.dbnodes[count.index].db_nic_ip : cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, tonumber(count.index) + 10)
    private_ip_address_allocation = "static"
  }
}

# Section for Linux Virtual machine 
resource azurerm_linux_virtual_machine "dbserver" {
  count                        = local.enable_deployment ? ((local.anydb_ostype == "Linux") ? local.vm_count : 0) : 0
  name                         = format("%s%02d-%s-vm", var.role, (count.index + 1), local.prefix)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.db-as[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids        = [azurerm_network_interface.nic[count.index].id]
  size                         = local.sku

  source_image_id = try(local.anydb.os.source_image_id, null)

  dynamic "source_image_reference" {
    for_each = range(try(local.anydb_image.publisher, null) == null ? 0 : 1)
    content {
      publisher = try(local.anydb_image.publisher, null)
      offer     = try(local.anydb_image.offer, null)
      sku       = try(local.anydb_image.sku, null)
      version   = try(local.anydb_image.version, "latest")
    }
  }

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name                 = format("%s%02d-%s-vm-osdisk", var.role, (count.index + 1), local.prefix)
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

  computer_name                   = "${local.prefix}${var.role}vm${count.index}"
  admin_username                  = local.dbnodes[count.index].authentication.username
  admin_password                  = lookup(local.dbnodes[count.index].authentication, "password", null)
  disable_password_authentication = local.dbnodes[count.index].authentication.type != "password" ? true : false

  admin_ssh_key {
    username   = local.dbnodes[count.index].authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
    role        = var.role
    SID         = local.prefix
  }
}


# Section for Windows Virtual machine based on a marketplace image 
resource azurerm_windows_virtual_machine "dbserver" {
  count                        = local.enable_deployment ? ((local.anydb_ostype == "Windows") ? local.vm_count : 0) : 0
  name                         = format("%s%02d-%s-vm", var.role, (count.index + 1), local.prefix)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.db-as[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids        = [azurerm_network_interface.nic[count.index].id]
  size                         = local.sku

  source_image_id = try(local.anydb_image.source_image_id, null)

  dynamic "source_image_reference" {
    for_each = range(try(local.anydb_image.publisher, null) == null ? 0 : 1)
    content {
      publisher = try(local.anydb_image.publisher, null)
      offer     = try(local.anydb_image.offer, null)
      sku       = try(local.anydb_image.sku, null)
      version   = try(local.anydb_image.version, "latest")
    }
  }

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name                 = format("%s%02d-%s-vm-osdisk", var.role, (count.index + 1), local.prefix)
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

  computer_name  = "${local.prefix}${var.role}vm${count.index}"
  admin_username = local.anydb_auth.username
  admin_password = local.anydb_auth.password

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
    role        = var.role
    SID         = local.prefix
  }
}


# Creates managed data disks
resource azurerm_managed_disk "disks" {
  count                = local.enable_deployment ? length(local.allDataDisks) : 0
  name                 = local.allDataDisks[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.allDataDisks[count.index].storage_account_type
  disk_size_gb         = local.allDataDisks[count.index].disk_size_gb
}

# Manages attaching a Disk to a Virtual Machine
resource azurerm_virtual_machine_data_disk_attachment "vm-disks" {
  count                     = local.enable_deployment ? length(local.allDataDisks) : 0
  managed_disk_id           = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id        = local.allDataDisks[count.index].virtual_machine_id
  caching                   = local.allDataDisks[count.index].caching
  write_accelerator_enabled = local.allDataDisks[count.index].write_accelerator_enabled
  lun                       = local.allDataDisks[count.index].lun
}

# # Creates managed log disks
# resource azurerm_managed_disk "log-disk" {
#   count                = local.enable_deployment ? length(local.allLogDisks) : 0
#   name                 = local.allLogDisks[count.index].name
#   location             = var.resource-group[0].location
#   resource_group_name  = var.resource-group[0].name
#   create_option        = "Empty"
#   storage_account_type = local.skuOfLogDisks
#   disk_size_gb         = local.sizeOfLogDisks
# }

# # Manages attaching a Disk to a Virtual Machine
# resource azurerm_virtual_machine_data_disk_attachment "vm-log-disk" {
#   count                     = local.enable_deployment ? length(local.allLogDisks) : 0
#   managed_disk_id           = azurerm_managed_disk.log-disk[count.index].id
#   virtual_machine_id        = local.allLogDisks[count.index].vmID
#   caching                   = local.allLogDisks[count.index].caching
#   write_accelerator_enabled = local.allLogDisks[count.index].writeAcceleratorEnabled
#   lun                       = local.allLogDisks[count.index].lun
# }

