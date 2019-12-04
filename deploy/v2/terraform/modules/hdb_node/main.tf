##################################################################################################################
# HANA DB Node
##################################################################################################################

# NETWORK SECURITY RULES =========================================================================================

# Creates network security rule to deny external traffic for SAP admin subnet
resource "azurerm_network_security_rule" "nsr-admin" {
  count                       = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 0 : 1
  name                        = "deny-inbound-traffic"
  resource_group_name         = var.nsg-admin[0].resource_group_name
  network_security_group_name = var.nsg-admin[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = var.infrastructure.vnets.sap.subnet_admin.prefix
}

# Creates network security rule for SAP DB subnet
resource "azurerm_network_security_rule" "nsr-db" {
  count                       = var.infrastructure.vnets.sap.subnet_db.nsg.is_existing ? 0 : 1
  name                        = "nsr-subnet-db"
  resource_group_name         = var.nsg-db[0].resource_group_name
  network_security_group_name = var.nsg-db[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.infrastructure.vnets.management.subnet_mgmt.prefix
  destination_address_prefix  = var.infrastructure.vnets.sap.subnet_db.prefix
}

# NICS ============================================================================================================

# Creates the admin traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "nics-dbnodes-admin" {
  for_each                      = local.dbnodes
  name                          = "${each.value.name}-admin-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-admin[0].id
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${each.value.name}-admin-nic-ip"
    subnet_id                     = var.subnet-sap-admin[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_admin.is_existing ? each.value.admin_nic_ip : lookup(each.value, "admin_nic_ip", false) != false ? each.value.admin_nic_ip : cidrhost(var.infrastructure.vnets.sap.subnet_admin.prefix, tonumber(each.key) + 4)
    private_ip_address_allocation = "static"
  }
}

# Creates the DB traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "nics-dbnodes-db" {
  for_each                      = local.dbnodes
  name                          = "${each.value.name}-db-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-db[0].id
  enable_accelerated_networking = true

  ip_configuration {
    primary                       = true
    name                          = "${each.value.name}-db-nic-ip"
    subnet_id                     = var.subnet-sap-db[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_db.is_existing ? each.value.db_nic_ip : lookup(each.value, "db_nic_ip", false) != false ? each.value.db_nic_ip : cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, tonumber(each.key) + 4)
    private_ip_address_allocation = "static"
  }
}

# VIRTUAL MACHINES ================================================================================================

# Creates database VM
resource "azurerm_virtual_machine" "vm-dbnode" {
  for_each                      = local.dbnodes
  name                          = each.value.name
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  primary_network_interface_id  = azurerm_network_interface.nics-dbnodes-db[each.key].id
  network_interface_ids         = [azurerm_network_interface.nics-dbnodes-admin[each.key].id, azurerm_network_interface.nics-dbnodes-db[each.key].id]
  vm_size                       = lookup(local.sizes, each.value.size).compute.vm_size
  delete_os_disk_on_termination = "true"

  dynamic "storage_os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, each.value.size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name              = "${each.value.name}-osdisk"
      caching           = disk.value.caching
      create_option     = "FromImage"
      managed_disk_type = disk.value.disk_type
      disk_size_gb      = disk.value.size_gb
    }
  }

  storage_image_reference {
    publisher = each.value.os.publisher
    offer     = each.value.os.offer
    sku       = each.value.os.sku
    version   = "latest"
  }

  dynamic "storage_data_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, each.value.size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching, write_accelerator = storage_type.write_accelerator }] if storage_type.name != "os"])
    content {
      name                      = "${each.value.name}-${disk.value.name}-${disk.value.id}"
      caching                   = disk.value.caching
      create_option             = "Empty"
      managed_disk_type         = disk.value.disk_type
      disk_size_gb              = disk.value.size_gb
      write_accelerator_enabled = disk.value.write_accelerator
      lun                       = disk.key
    }
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = each.value.authentication.username
    admin_password = lookup(each.value.authentication, "password", null)
  }

  os_profile_linux_config {
    disable_password_authentication = each.value.authentication.type != "password" ? true : false
    dynamic "ssh_keys" {
      for_each = each.value.authentication.type != "password" ? ["key"] : []
      content {
        path     = "/home/${each.value.authentication.username}/.ssh/authorized_keys"
        key_data = file(var.sshkey.path_to_public_key)
      }
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}
