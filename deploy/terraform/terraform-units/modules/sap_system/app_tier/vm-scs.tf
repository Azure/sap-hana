# Create SCS NICs
resource "azurerm_network_interface" "scs" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.scs_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.scs_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id
    private_ip_address = var.application.use_DHCP ? (
      null) : (
      try(local.scs_nic_ips[count.index],
        cidrhost(local.sub_app_exists ?
          data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] :
          azurerm_subnet.subnet_sap_app[0].address_prefixes[0],
          tonumber(count.index) + local.ip_offsets.scs_vm
        )
      )
    )
    private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
  }
}

resource "azurerm_network_interface_application_security_group_association" "scs" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.scs_server_count : 0
  network_interface_id          = azurerm_network_interface.scs[count.index].id
  application_security_group_id = azurerm_application_security_group.app[0].id
}


// Create Admin NICs
resource "azurerm_network_interface" "scs_admin" {
  provider                      = azurerm.main
  count                         = local.enable_deployment && var.application.dual_nics ? local.scs_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.admin_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.admin_subnet.id
    private_ip_address = var.application.use_DHCP ? (
      null) : (
      try(local.scs_admin_nic_ips[count.index],
        cidrhost(var.admin_subnet.address_prefixes[0],
          tonumber(count.index) + local.admin_ip_offsets.scs_vm
        )
      )
    )
    private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
  }
}

# Associate SCS VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "scs" {
  provider                = azurerm.main
  count                   = local.enable_scs_lb_deployment ? local.scs_server_count : 0
  network_interface_id    = azurerm_network_interface.scs[count.index].id
  ip_configuration_name   = azurerm_network_interface.scs[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.scs[0].id
}

# Create the SCS Linux VM(s)
resource "azurerm_linux_virtual_machine" "scs" {
  provider            = azurerm.main
  depends_on          = [var.anydb_vm_ids, var.hdb_vm_ids]
  count               = local.enable_deployment && (upper(local.scs_ostype) == "LINUX") ? local.scs_server_count : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.scs_computer_names[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the scs servers in a proximity placement group
  proximity_placement_group_id = local.scs_no_ppg ? (
    null) : (
    local.scs_zonal_deployment ? var.ppg[count.index % max(local.scs_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_scs_avset ? azurerm_availability_set.scs[count.index % max(local.scs_zone_count, 1)].id : null

  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_scs_avset ? null : local.scs_zones[count.index % max(local.scs_zone_count, 1)]
  network_interface_ids = var.application.dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.scs_admin[count.index].id, azurerm_network_interface.scs[count.index].id]) : (
      [azurerm_network_interface.scs[count.index].id, azurerm_network_interface.scs_admin[count.index].id]
    )
    ) : (
    [azurerm_network_interface.scs[count.index].id]
  )

  size                            = length(local.scs_size) > 0 ? local.scs_size : local.scs_sizing.compute.vm_size
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
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application.scs_tags, {})
}

# Create the SCS Windows VM(s)
resource "azurerm_windows_virtual_machine" "scs" {
  provider            = azurerm.main
  depends_on          = [var.anydb_vm_ids, var.hdb_vm_ids]
  count               = local.enable_deployment && (upper(local.scs_ostype) == "WINDOWS") ? local.scs_server_count : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.scs_computer_names[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the scs servers in a proximity placement group
  proximity_placement_group_id = local.scs_no_ppg ? (
    null) : (
    local.scs_zonal_deployment ? var.ppg[count.index % max(local.scs_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_scs_avset ? azurerm_availability_set.scs[count.index % max(local.scs_zone_count, 1)].id : null

  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_scs_avset ? null : local.scs_zones[count.index % max(local.scs_zone_count, 1)]

  network_interface_ids = var.application.dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.scs_admin[count.index].id, azurerm_network_interface.scs[count.index].id]) : (
      [azurerm_network_interface.scs[count.index].id, azurerm_network_interface.scs_admin[count.index].id]
    )
    ) : (
    [azurerm_network_interface.scs[count.index].id]
  )

  size           = length(local.scs_size) > 0 ? local.scs_size : local.scs_sizing.compute.vm_size
  admin_username = var.sid_username
  admin_password = var.sid_password

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
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application.scs_tags, {})
}

# Creates managed data disk
resource "azurerm_managed_disk" "scs" {
  provider               = azurerm.main
  count                  = local.enable_deployment ? length(local.scs_data_disks) : 0
  name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.scs_virtualmachine_names[local.scs_data_disks[count.index].vm_index], local.scs_data_disks[count.index].suffix)
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.scs_data_disks[count.index].storage_account_type
  disk_size_gb           = local.scs_data_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

  zones = !local.use_scs_avset ? (
    upper(local.scs_ostype) == "LINUX" ? (
      [azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone]) : (
      [azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone]
    )) : (
    null
  )
}

resource "azurerm_virtual_machine_data_disk_attachment" "scs" {
  provider        = azurerm.main
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
