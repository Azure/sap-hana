


#############################################################################
# RESOURCES
#############################################################################


resource azurerm_network_interface "anydbnic" {
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

resource azurerm_linux_virtual_machine "main" {
  count                        = local.enable_deployment ? local.vm_count : 0
  name                         = format("%s%02d-%s-vm", var.role, (count.index + 1), local.prefix)
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.db-as[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids        = [azurerm_network_interface.anydbnic[count.index].id]
  size                         = local.sku

  source_image_reference {
    publisher = local.dbnodes[count.index].os.publisher
    offer     = local.dbnodes[count.index].os.offer
    sku       = local.dbnodes[count.index].os.sku
    version   = "latest"
  }

  os_disk {
    name                 = format("%s-%s%02d-diskos", var.role, local.prefix, (count.index + 1))
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

