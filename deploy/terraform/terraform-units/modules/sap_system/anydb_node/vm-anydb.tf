#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_network_interface" "anydb_db" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.db_server_count : 0
  name                          = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.db_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary   = true
    name      = "ipconfig1"
    subnet_id = var.db_subnet.id

    private_ip_address = local.use_DHCP ? (
      null) : (
      try(local.anydb_vms[count.index].db_nic_ip, "false") != "false" ? (
        local.anydb_vms[count.index].db_nic_ip) : (
        cidrhost(var.db_subnet.address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.anydb_db_vm)
      )
    )

    private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
  }
}

resource "azurerm_network_interface_application_security_group_association" "db" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.db_server_count : 0
  network_interface_id          = azurerm_network_interface.anydb_db[count.index].id
  application_security_group_id = var.db_asg_id
}

# Creates the Admin traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "anydb_admin" {
  provider                      = azurerm.main
  count                         = local.enable_deployment && local.anydb_dual_nics ? local.db_server_count : 0
  name                          = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.admin_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary   = true
    name      = "ipconfig1"
    subnet_id = var.admin_subnet.id

    private_ip_address = local.use_DHCP ? (
      null) : (
      try(local.anydb_vms[count.index].admin_nic_ip, "false") != "false" ? (
        local.anydb_vms[count.index].admin_nic_ip) : (
        cidrhost(var.admin_subnet.address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.anydb_admin_vm)
      )
    )
    private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
  }
}

// Section for Linux Virtual machine 
resource "azurerm_linux_virtual_machine" "dbserver" {
  provider            = azurerm.main
  depends_on          = [var.anchor_vm]
  count               = local.enable_deployment ? ((upper(local.anydb_ostype) == "LINUX") ? local.db_server_count : 0) : 0
  name                = local.anydb_vms[count.index].name
  computer_name       = local.anydb_vms[count.index].computername
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  admin_username                  = var.sid_username
  admin_password                  = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication = !local.enable_auth_password

  dynamic "admin_ssh_key" {
    for_each = range(var.deployment == "new" ? 1 : (local.enable_auth_password ? 0 : 1))
    content {
      username   = var.sid_username
      public_key = var.sdu_public_key
    }
  }

  custom_data = var.deployment == "new" ? var.cloudinit_growpart_config : null

  dynamic "os_disk" {
    iterator = disk
    for_each = range(length(local.os_disk))
    content {
      name                   = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.osdisk)
      caching                = local.os_disk[0].caching
      storage_account_type   = local.os_disk[0].storage_account_type
      disk_size_gb           = local.os_disk[0].disk_size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

    }
  }

  //If no ppg defined do not put the database in a proximity placement group
  proximity_placement_group_id = local.no_ppg ? (
    null) : (
    local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_avset ? (
    local.availabilitysets_exist ? (
      data.azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id) : (
      azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id
    )
  ) : null
  zone = local.use_avset ? null : local.zones[count.index % max(local.db_zone_count, 1)]

  network_interface_ids = local.anydb_dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.anydb_admin[count.index].id, azurerm_network_interface.anydb_db[count.index].id]) : (
      [azurerm_network_interface.anydb_db[count.index].id, azurerm_network_interface.anydb_admin[count.index].id]
    )) : (
    [azurerm_network_interface.anydb_db[count.index].id]
  )

  size = local.anydb_vms[count.index].size

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
  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = local.tags

  lifecycle  {
  ignore_changes = [
    // Ignore changes to computername
    tags,
    computer_name
  ]
  }

}

// Section for Windows Virtual machine 
resource "azurerm_windows_virtual_machine" "dbserver" {
  provider            = azurerm.main
  depends_on          = [var.anchor_vm]
  count               = local.enable_deployment ? ((upper(local.anydb_ostype) == "WINDOWS") ? local.db_server_count : 0) : 0
  name                = local.anydb_vms[count.index].name
  computer_name       = local.anydb_vms[count.index].computername
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  admin_username      = var.sid_username
  admin_password      = var.sid_password

  dynamic "os_disk" {
    iterator = disk
    for_each = range(length(local.os_disk))
    content {
      name                   = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.osdisk)
      caching                = local.os_disk[0].caching
      storage_account_type   = local.os_disk[0].storage_account_type
      disk_size_gb           = local.os_disk[0].disk_size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

    }
  }

  //If no ppg defined do not put the database in a proximity placement group
  proximity_placement_group_id = local.no_ppg ? (
    null) : (
    local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_avset ? (
    local.availabilitysets_exist ? (
      data.azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id) : (
      azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id
    )
  ) : null
  zone = local.use_avset ? null : local.zones[count.index % max(local.db_zone_count, 1)]

  network_interface_ids = local.anydb_dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.anydb_admin[count.index].id, azurerm_network_interface.anydb_db[count.index].id]) : (
      [azurerm_network_interface.anydb_db[count.index].id, azurerm_network_interface.anydb_admin[count.index].id]
    )) : (
    [azurerm_network_interface.anydb_db[count.index].id]
  )

  size = local.anydb_vms[count.index].size

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


  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = local.tags
  lifecycle  {
  ignore_changes = [
    // Ignore changes to computername
    computer_name, 
    tags
  ]
  }
}

// Creates managed data disks
resource "azurerm_managed_disk" "disks" {
  provider               = azurerm.main
  count                  = local.enable_deployment ? length(local.anydb_disks) : 0
  name                   = local.anydb_disks[count.index].name
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.anydb_disks[count.index].storage_account_type
  disk_size_gb           = local.anydb_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
  disk_iops_read_write   = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? local.anydb_disks[count.index].disk_iops_read_write : null
  disk_mbps_read_write   = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? local.anydb_disks[count.index].disk_mbps_read_write : null


  zones = !local.use_avset ? (
    upper(local.anydb_ostype) == "LINUX" ? (
      [azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone]) : (
      [azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone]
  )) : null

}

// Manages attaching a Disk to a Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disks" {
  provider        = azurerm.main
  count           = local.enable_deployment ? length(local.anydb_disks) : 0
  managed_disk_id = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id = upper(local.anydb_ostype) == "LINUX" ? (
    azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id
  )
  caching                   = local.anydb_disks[count.index].caching
  write_accelerator_enabled = local.anydb_disks[count.index].write_accelerator_enabled
  lun                       = local.anydb_disks[count.index].lun
}


# VM Extension 
resource "azurerm_virtual_machine_extension" "anydb_lnx_aem_extension" {
  provider             = azurerm.main
  count                = local.enable_deployment ? upper(local.anydb_ostype) == "LINUX" ? local.db_server_count : 0 : 0
  name                 = "MonitorX64Linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.dbserver[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Linux"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "anydb_win_aem_extension" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (upper(local.anydb_ostype) == "WINDOWS" ? local.db_server_count : 0) : 0
  name                 = "MonitorX64Windows"
  virtual_machine_id   = azurerm_windows_virtual_machine.dbserver[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Windows"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}
