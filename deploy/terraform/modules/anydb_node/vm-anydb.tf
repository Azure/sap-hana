
locals {


  dataDisks            = lookup(var.datadisks, local.size)
  dataDisksSettingList = split(";", local.dataDisks)
  nrOfDataDisks        = local.dataDisksSettingList[0]
  #Helper variable for disk name enumeration
  disks                        = range(local.nrOfDataDisks)
  sizeOfDataDisks              = local.dataDisksSettingList[1]
  nameOfDataDisks              = local.dataDisksSettingList[2]
  skuOfDataDisks               = local.dataDisksSettingList[3]
  cachingOfDataDisks           = local.dataDisksSettingList[4]
  writeAcceleratorForDataDisks = local.dataDisksSettingList[5]

  allDataDisks = flatten([for vm in azurerm_linux_virtual_machine.main : [for disk in local.disks : {
    name                    = format("%s%s%02d", vm.name, local.nameOfDataDisks, disk + 1)
    sku                     = local.skuOfDataDisks
    writeAcceleratorEnabled = local.writeAcceleratorForDataDisks
    diskSizeGB              = local.sizeOfDataDisks
    caching                 = local.cachingOfDataDisks
    lun                     = disk
    vmID                    = vm.id
  }]])

  logDisksData        = lookup(var.logdisks, local.size)
  logDisksSettingList = split(";", local.logDisksData)
  nrOfLogDisks        = local.logDisksSettingList[0]
  #Helper variable for disk name enumeration
  logDisks                    = range(local.nrOfLogDisks)
  sizeOfLogDisks              = local.logDisksSettingList[1]
  nameOfLogDisks              = local.logDisksSettingList[2]
  skuOfLogDisks               = local.logDisksSettingList[3]
  cachingOfLogDisks           = local.logDisksSettingList[4]
  writeAcceleratorForLogDisks = local.logDisksSettingList[5]

  allLogDisks = flatten([for vm in azurerm_linux_virtual_machine.main : [for disk in local.logDisks : {
    name                    = format("%s%s%02d", vm.name, local.nameOfLogDisks, disk + 1)
    sku                     = local.skuOfLogDisks
    writeAcceleratorEnabled = local.writeAcceleratorForLogDisks
    diskSizeGB              = local.sizeOfLogDisks
    caching                 = local.cachingOfLogDisks
    lun                     = disk + local.nrOfDataDisks
    vmID                    = vm.id
  }]])


  sku = lookup(var.skus, local.size)
}



#############################################################################
# RESOURCES
#############################################################################


resource azurerm_network_interface "nic" {
  count               = local.enable_deployment ? local.vm_count : 0
  name                = format("%s-%s%02d-nic", local.prefix, var.role, (count.index + 1))
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name

  ip_configuration {
    primary                       = true
    name                          = "${local.dbnodes[count.index].name}-db-nic-ip"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_db.is_existing ? data.azurerm_subnet.subnet-anydb[0].id : azurerm_subnet.subnet-anydb[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_db.is_existing ? local.dbnodes[count.index].db_nic_ip : lookup(local.dbnodes[count.index], "db_nic_ip", false) != false ? local.dbnodes[count.index].db_nic_ip : cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, tonumber(count.index) + 10)
    private_ip_address_allocation = "static"
  }
}


# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "db-as" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = format("%s-%s-lb", local.prefix, var.role)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}


resource azurerm_linux_virtual_machine "main" {
  count                        = local.enable_deployment ? local.vm_count : 0
  name                         = format("%s-%s%02d", local.prefix, var.role, (count.index + 1))
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.db-as[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids        = [azurerm_network_interface.nic[count.index].id]
  size                         = local.sku

  source_image_reference {
    publisher = local.dbnodes[count.index].os.publisher
    offer     = local.dbnodes[count.index].os.offer
    sku       = local.dbnodes[count.index].os.sku
    version   = "latest"
  }

  os_disk {
    name                 = format("%s-%s%02d-diskos", local.prefix, var.role, (count.index + 1))
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
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

# Creates managed data disks
resource azurerm_managed_disk "data-disk" {
  count                = length(local.allDataDisks)
  name                 = local.allDataDisks[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.skuOfDataDisks
  disk_size_gb         = local.sizeOfDataDisks
}

# Manages attaching a Disk to a Virtual Machine
resource azurerm_virtual_machine_data_disk_attachment "vm-data-disk" {
  count           = length(local.allDataDisks)
  managed_disk_id = azurerm_managed_disk.data-disk[count.index].id
  #virtual_machine_id        = azurerm_virtual_machine.main[0].id
  virtual_machine_id        = local.allDataDisks[count.index].vmID
  caching                   = local.allDataDisks[count.index].caching
  write_accelerator_enabled = local.allDataDisks[count.index].writeAcceleratorEnabled
  lun                       = local.allDataDisks[count.index].lun
}

# Creates managed log disks
resource azurerm_managed_disk "log-disk" {
  count                = length(local.allLogDisks)
  name                 = local.allLogDisks[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.skuOfLogDisks
  disk_size_gb         = local.sizeOfLogDisks
}

# Manages attaching a Disk to a Virtual Machine
resource azurerm_virtual_machine_data_disk_attachment "vm-log-disk" {
  count           = length(local.allLogDisks)
  managed_disk_id = azurerm_managed_disk.log-disk[count.index].id
  #virtual_machine_id        = azurerm_virtual_machine.main[0].id
  virtual_machine_id        = local.allLogDisks[count.index].vmID
  caching                   = local.allLogDisks[count.index].caching
  write_accelerator_enabled = local.allLogDisks[count.index].writeAcceleratorEnabled
  lun                       = local.allLogDisks[count.index].lun
}

