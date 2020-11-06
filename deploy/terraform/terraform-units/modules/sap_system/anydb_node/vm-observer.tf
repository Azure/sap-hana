
# Create observer VM
resource "azurerm_network_interface" "observer" {
  count                         = local.deploy_observer ? length(local.zones) : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.observer_virtualmachine_names[count.index], local.resource_suffixes.nic)
  resource_group_name           = var.resource_group[0].name
  location                      = var.resource_group[0].location
  enable_accelerated_networking = false

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.db_subnet.id
    private_ip_address = try(local.observer.nic_ips[count.index],
      cidrhost(var.db_subnet.address_prefixes[0], tonumber(count.index) + local.anydb_ip_offsets.observer_db_vm)
    )
    private_ip_address_allocation = "static"
  }
}

# Create the Linux Application VM(s)
resource "azurerm_linux_virtual_machine" "observer" {
  count               = local.deploy_observer && upper(local.anydb_ostype) == "LINUX" ? length(local.zones) : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.observer_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.observer_computer_names[count.index]
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count,1)].id : var.ppg[0].id
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? null : azurerm_availability_set.anydb[count.index % max(local.db_zone_count,1)].id) : (
    azurerm_availability_set.anydb[0].id
  )

  zone = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? local.zones[count.index % max(local.db_zone_count,1)] : null) : (
    null
  )

  network_interface_ids = [
    azurerm_network_interface.observer[count.index].id
  ]
  size                            = local.observer_size
  admin_username                  = local.observer_authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = format("%s%s%s%s", local.prefix, var.naming.separator, local.observer_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.observer_custom_image ? local.observer_custom_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.observer_custom_image ? 0 : 1)
    content {
      publisher = local.observer_os.publisher
      offer     = local.observer_os.offer
      sku       = local.observer_os.sku
      version   = local.observer_os.version
    }
  }

  admin_ssh_key {
    username   = local.observer_authentication.username
    public_key = data.azurerm_key_vault_secret.sid_pk[0].value
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }
}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "observer" {
  count               = local.deploy_observer && upper(local.anydb_ostype) == "WINDOWS" ? length(local.zones) : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.observer_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name       = local.observer_computer_names[count.index]
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % max(local.db_zone_count,1)].id : var.ppg[0].id
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? null : azurerm_availability_set.anydb[count.index % max(local.db_zone_count,1)].id) : (
    azurerm_availability_set.anydb[0].id
  )

  zone = local.zonal_deployment ? (
    local.db_server_count == local.db_zone_count ? local.zones[count.index % max(local.db_zone_count,1)] : null) : (
    null
  )

  network_interface_ids = [
    azurerm_network_interface.observer[count.index].id
  ]

  size           = local.observer_size
  admin_username = local.observer_authentication.username
  admin_password = local.observer_authentication.password

  os_disk {
    name                 = format("%s%s%s%s", local.prefix, var.naming.separator, local.observer_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.observer_custom_image ? local.observer_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.observer_custom_image ? 0 : 1)
    content {
      publisher = local.observer_os.publisher
      offer     = local.observer_os.offer
      sku       = local.observer_os.sku
      version   = local.observer_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag.primary_blob_endpoint
  }
}
