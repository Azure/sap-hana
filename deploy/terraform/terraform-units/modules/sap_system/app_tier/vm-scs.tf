# Create SCS NICs
resource "azurerm_network_interface" "scs" {
  count                         = local.enable_deployment ? local.scs_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.scs_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id
    private_ip_address = local.use_DHCP ? (
      null) : (
      try(local.scs_nic_ips[count.index],
        cidrhost(local.sub_app_exists ?
          data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] :
          azurerm_subnet.subnet_sap_app[0].address_prefixes[0],
          tonumber(count.index) + local.ip_offsets.scs_vm
        )
      )
    )
    private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
  }
}

// Create Admin NICs
resource "azurerm_network_interface" "scs_admin" {
  count                         = local.enable_deployment && local.apptier_dual_nics ? local.scs_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.admin_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.admin_subnet.id
    private_ip_address = local.use_DHCP ? (
      null) : (
      try(local.scs_admin_nic_ips[count.index],
        cidrhost(var.admin_subnet.id.address_prefixes[0],
          tonumber(count.index) + local.admin_ip_offsets.scs_vm
        )
      )
    )
    private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
  }
}

# Associate SCS VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "scs" {
  count                   = local.enable_deployment ? local.scs_server_count : 0
  network_interface_id    = azurerm_network_interface.scs[count.index].id
  ip_configuration_name   = azurerm_network_interface.scs[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.scs[0].id
}

# Create the SCS Linux VM(s)
resource "azurerm_linux_virtual_machine" "scs" {
  depends_on          = [var.anydb_vms, var.hdb_vms]
  count               = local.enable_deployment && (upper(local.scs_ostype) == "LINUX") ? local.scs_server_count : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.scs_computer_names[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If more than one servers are deployed into a zone put them in an availability set and not a zone
  availability_set_id = local.scs_zonal_deployment && (local.scs_server_count == local.scs_zone_count) ? (
    null) : (
    local.scs_zone_count > 1 ? (
      azurerm_availability_set.scs[count.index % max(local.scs_zone_count, 1)].id) : (
      azurerm_availability_set.scs[0].id
    )
  )
  proximity_placement_group_id = local.scs_zonal_deployment ? var.ppg[count.index % max(local.scs_zone_count, 1)].id : var.ppg[0].id
  zone = local.scs_zonal_deployment && (local.scs_server_count == local.scs_zone_count) ? (
    local.scs_zones[count.index % max(local.scs_zone_count, 1)]) : (
    null
  )

  network_interface_ids = local.apptier_dual_nics ? (
    [azurerm_network_interface.scs_admin[count.index].id, azurerm_network_interface.scs[count.index].id]) : (
    [azurerm_network_interface.scs[count.index].id]
  )

  size                            = local.scs_sizing.compute.vm_size
  admin_username                  = local.sid_auth_username
  disable_password_authentication = ! local.enable_auth_password
  admin_password                  = local.sid_auth_password

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten(
      [
        for storage_type in local.scs_sizing.storage : [
          for disk_count in range(storage_type.count) :
          {
            name      = storage_type.name,
            id        = disk_count,
            disk_type = storage_type.disk_type,
            size_gb   = storage_type.size_gb,
            caching   = storage_type.caching
          }
        ]
        if storage_type.name == "os"
      ]
    )

    content {
      name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = local.scs_custom_image ? local.scs_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.scs_custom_image ? 0 : 1)
    content {
      publisher = local.scs_os.publisher
      offer     = local.scs_os.offer
      sku       = local.scs_os.sku
      version   = local.scs_os.version
    }
  }

  dynamic "admin_ssh_key" {
    for_each = range(local.enable_auth_password ? 0 : 1)
    content {
      username   = local.sid_auth_username
      public_key = data.azurerm_key_vault_secret.sid_pk[0].value
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }

  tags = local.scs_tags
}

# Create the SCS Windows VM(s)
resource "azurerm_windows_virtual_machine" "scs" {
  depends_on          = [var.anydb_vms, var.hdb_vms]
  count               = local.enable_deployment && (upper(local.scs_ostype) == "WINDOWS") ? local.scs_server_count : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.scs_computer_names[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If more than one servers are deployed into a zone put them in an availability set and not a zone
  availability_set_id = local.scs_zonal_deployment && (local.scs_server_count == local.scs_zone_count) ? (
    null) : (
    local.scs_zone_count > 1 ? (
      azurerm_availability_set.scs[count.index % max(local.scs_zone_count, 1)].id) : (
      azurerm_availability_set.scs[0].id
    )
  )
  proximity_placement_group_id = local.scs_zonal_deployment ? var.ppg[count.index % max(local.scs_zone_count, 1)].id : var.ppg[0].id
  zone = local.scs_zonal_deployment && (local.scs_server_count == local.scs_zone_count) ? (
    local.scs_zones[count.index % max(local.scs_zone_count, 1)]) : (
    null
  )

  network_interface_ids = local.apptier_dual_nics ? (
    [azurerm_network_interface.scs_admin[count.index].id, azurerm_network_interface.scs[count.index].id]) : (
    [azurerm_network_interface.scs[count.index].id]
  )

  size           = local.scs_sizing.compute.vm_size
  admin_username = local.sid_auth_username
  admin_password = local.sid_auth_password

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten(
      [
        for storage_type in local.scs_sizing.storage : [
          for disk_count in range(storage_type.count) :
          {
            name      = storage_type.name,
            id        = disk_count,
            disk_type = storage_type.disk_type,
            size_gb   = storage_type.size_gb,
            caching   = storage_type.caching
          }
        ]
        if storage_type.name == "os"
      ]
    )

    content {
      name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = local.scs_custom_image ? local.scs_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.scs_custom_image ? 0 : 1)
    content {
      publisher = local.scs_os.publisher
      offer     = local.scs_os.offer
      sku       = local.scs_os.sku
      version   = local.scs_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }

  tags = local.scs_tags
}

# Creates managed data disk
resource "azurerm_managed_disk" "scs" {
  count                  = local.enable_deployment ? length(local.scs_data_disks) : 0
  name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.scs_data_disks[count.index].suffix)
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.scs_data_disks[count.index].storage_account_type
  disk_size_gb           = local.scs_data_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

  zones = local.scs_zonal_deployment && (local.scs_server_count == local.scs_zone_count) ? (
    upper(local.scs_ostype) == "LINUX" ? (
      [azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone]) : (
      [azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone]
    )) : (
    null
  )
}

resource "azurerm_virtual_machine_data_disk_attachment" "scs" {
  count           = local.enable_deployment ? length(local.scs_data_disks) : 0
  managed_disk_id = azurerm_managed_disk.scs[count.index].id
  virtual_machine_id = upper(local.scs_ostype) == "LINUX" ? (
    azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].id
  )
  caching                   = local.scs_data_disks[count.index].caching
  write_accelerator_enabled = local.scs_data_disks[count.index].write_accelerator_enabled
  lun                       = local.scs_data_disks[count.index].lun
}
