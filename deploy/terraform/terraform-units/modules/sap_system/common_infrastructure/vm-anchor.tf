
# Create Anchor VM
resource "azurerm_network_interface" "anchor" {
  count                         = local.deploy_anchor ? length(local.zones) : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, local.anchor_virtualmachine_names[count.index], local.resource_suffixes.nic)
  resource_group_name           = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                      = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  enable_accelerated_networking = local.enable_accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = local.sub_db_exists ? data.azurerm_subnet.db[0].id : azurerm_subnet.db[0].id
    private_ip_address = local.anchor_use_DHCP ? (
      null) : (
      try(local.anchor_nic_ips[count.index], cidrhost(local.sub_db_exists ? data.azurerm_subnet.db[0].address_prefixes[0] : azurerm_subnet.db[0].address_prefixes[0], (count.index + 5)))
    )
    private_ip_address_allocation = local.anchor_use_DHCP ? "Dynamic" : "Static"
  }
}

# Create the Linux Application VM(s)
resource "azurerm_linux_virtual_machine" "anchor" {
  count                        = local.deploy_anchor && (local.anchor_ostype == "LINUX") ? length(local.zones) : 0
  name                         = format("%s%s%s%s", local.prefix, var.naming.separator, local.anchor_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name                = local.anchor_computer_names[count.index]
  resource_group_name          = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                     = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  proximity_placement_group_id = local.ppg_exists ? data.azurerm_proximity_placement_group.ppg[count.index].id : azurerm_proximity_placement_group.ppg[count.index].id
  zone                         = local.zones[count.index]

  network_interface_ids = [
    azurerm_network_interface.anchor[count.index].id
  ]
  size                            = local.anchor_size
  admin_username                  = local.sid_auth_username
  disable_password_authentication = ! local.enable_anchor_auth_password
  admin_password                  = local.enable_anchor_auth_key ? null : local.sid_auth_password

  os_disk {
    name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.anchor_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
  }

  source_image_id = local.anchor_custom_image ? local.anchor_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.anchor_custom_image ? 0 : 1)
    content {
      publisher = local.anchor_os.publisher
      offer     = local.anchor_os.offer
      sku       = local.anchor_os.sku
      version   = local.anchor_os.version
    }
  }

  admin_ssh_key {
    username   = local.sid_auth_username
    public_key = data.azurerm_key_vault_secret.sid_pk[0].value
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.storage_bootdiag.primary_blob_endpoint
  }

  additional_capabilities {
    ultra_ssd_enabled = local.enable_anchor_ultra[count.index]
  }

}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "anchor" {
  count                        = local.deploy_anchor && (local.anchor_ostype == "WINDOWS") ? length(local.zones) : 0
  name                         = format("%s%s%s%s", local.prefix, var.naming.separator, local.anchor_virtualmachine_names[count.index], local.resource_suffixes.vm)
  computer_name                = local.anchor_computer_names[count.index]
  resource_group_name          = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                     = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  proximity_placement_group_id = local.ppg_exists ? data.azurerm_proximity_placement_group.ppg[count.index].id : azurerm_proximity_placement_group.ppg[count.index].id
  zone                         = local.zones[count.index]

  network_interface_ids = [
    azurerm_network_interface.anchor[count.index].id
  ]

  size           = local.anchor_size
  admin_username = local.sid_auth_username
  admin_password = local.sid_auth_password

  os_disk {
    name                 = format("%s%s%s%s", local.prefix, var.naming.separator, local.anchor_virtualmachine_names[count.index], local.resource_suffixes.osdisk)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.anchor_custom_image ? local.anchor_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.anchor_custom_image ? 0 : 1)
    content {
      publisher = local.anchor_os.publisher
      offer     = local.anchor_os.offer
      sku       = local.anchor_os.sku
      version   = local.anchor_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.storage_bootdiag.primary_blob_endpoint
  }

  additional_capabilities {
    ultra_ssd_enabled = local.enable_anchor_ultra[count.index]
  }

}
