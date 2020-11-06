#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_network_interface" "anydb_db" {
  count                         = local.enable_deployment ? local.db_server_count : 0
  name                          = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.db_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary   = true
    name      = "ipconfig1"
    subnet_id = var.db_subnet.id

    private_ip_address = try(local.anydb_vms[count.index].db_nic_ip, false) != false ? (
      local.anydb_vms[count.index].db_nic_ip) : (
      cidrhost(var.db_subnet.address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.anydb_db_vm)
    )

    private_ip_address_allocation = "static"
  }
}

# Creates the Admin traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "anydb_admin" {
  count                         = local.enable_deployment && local.anydb_dual_nics ? local.db_server_count : 0
  name                          = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.admin_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary   = true
    name      = "ipconfig1"
    subnet_id = var.admin_subnet.id

    private_ip_address = try(local.anydb_vms[count.index].admin_nic_ip, false) != false ? (
      local.anydb_vms[count.index].admin_nic_ip) : (
      cidrhost(var.admin_subnet[0].address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.anydb_admin_vm)
    )
    private_ip_address_allocation = "static"
  }
}

// Section for Linux Virtual machine 
resource "azurerm_linux_virtual_machine" "dbserver" {
  count               = local.enable_deployment ? ((upper(local.anydb_ostype) == "LINUX") ? local.db_server_count : 0) : 0
  name                = local.anydb_vms[count.index].name
  computer_name       = local.anydb_vms[count.index].computername
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count,1)].id : var.ppg[0].id
  //Ultra disk requires zonal deployment
  availability_set_id = local.enable_ultradisk ? null : (
    local.zonal_deployment && local.db_server_count == local.db_zone_count ? null : azurerm_availability_set.anydb[count.index % max(local.db_zone_count,1)].id
  )

  zone = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? local.zones[count.index % max(local.db_zone_count,1)] : null) : (
    null
  )

  network_interface_ids = local.anydb_dual_nics ? (
    [azurerm_network_interface.anydb_admin[count.index].id, azurerm_network_interface.anydb_db[count.index].id]) : (
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

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.anydb_size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name                 = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.osdisk)
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

  admin_username                  = local.sid_auth_username
  admin_password                  = local.sid_auth_password
  disable_password_authentication = ! local.enable_auth_password

  dynamic "admin_ssh_key" {
    for_each = range(local.enable_auth_password ? 0 : 1)
    content {
      username   = local.anydb_vms[count.index].authentication.username
      public_key = data.azurerm_key_vault_secret.sid_pk[0].value
    }
  }

  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
    SID         = upper(local.sap_sid)
  }
}

// Section for Windows Virtual machine 
resource "azurerm_windows_virtual_machine" "dbserver" {
  count               = local.enable_deployment ? ((upper(local.anydb_ostype) == "WINDOWS") ? local.db_server_count : 0) : 0
  name                = local.anydb_vms[count.index].name
  computer_name       = local.anydb_vms[count.index].computername
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count,1)].id : var.ppg[0].id
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  //Ultra disk requires zonal deployment
  availability_set_id = local.enable_ultradisk ? null : (
    local.zonal_deployment && local.db_server_count == local.db_zone_count ? null : azurerm_availability_set.anydb[count.index % max(local.db_zone_count,1)].id
  )

  zone = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? local.zones[count.index % max(local.db_zone_count,1)] : null) : (
    null
  )

  network_interface_ids = local.anydb_dual_nics ? (
    [azurerm_network_interface.anydb_admin[count.index].id, azurerm_network_interface.anydb_db[count.index].id]) : (
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

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.anydb_size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name                 = format("%s%s", local.anydb_vms[count.index].name, local.resource_suffixes.osdisk)
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

  admin_username = local.sid_auth_username
  admin_password = local.sid_auth_password

  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }
  tags = {
    environment = "SAP"
    SID         = upper(local.sap_sid)
  }
}

// Creates managed data disks
resource "azurerm_managed_disk" "disks" {
  count                = local.enable_deployment ? length(local.anydb_disks) : 0
  name                 = local.anydb_disks[count.index].name
  location             = var.resource_group[0].location
  resource_group_name  = var.resource_group[0].name
  create_option        = "Empty"
  storage_account_type = local.anydb_disks[count.index].storage_account_type
  disk_size_gb         = local.anydb_disks[count.index].disk_size_gb

  zones = local.enable_ultradisk || local.db_server_count == local.db_zone_count ? (
    upper(local.anydb_ostype) == "LINUX" ? (
      [azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone]) : (
      [azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone]
  )) : null

}

// Manages attaching a Disk to a Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disks" {
  count           = local.enable_deployment ? length(azurerm_managed_disk.disks) : 0
  managed_disk_id = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id = upper(local.anydb_ostype) == "LINUX" ? (
    azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id
  )
  caching                   = local.anydb_disks[count.index].caching
  write_accelerator_enabled = local.anydb_disks[count.index].write_accelerator_enabled
  lun                       = local.anydb_disks[count.index].lun
}
