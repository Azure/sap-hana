##################################################################################################################
# HANA Database Node
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
  destination_address_prefix  = "${var.infrastructure.vnets.sap.subnet_admin.prefix}"
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
  source_address_prefix       = "${var.infrastructure.vnets.management.subnet_mgmt.prefix}"
  destination_address_prefix  = "${var.infrastructure.vnets.sap.subnet_db.prefix}"
}

# NICS ============================================================================================================

# Creates the admin traffic NIC and private IP address for HANA database nodes
resource "azurerm_network_interface" "nic-hdb-admin" {
  count                         = length(var.databases)
  name                          = lookup(var.databases[count.index].admin_nic, "name", false) != false ? var.databases[count.index].admin_nic.name : "${var.databases[count.index].name}-admin-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-admin[0].id
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.databases[count.index].name}-admin-nic-ip"
    subnet_id                     = var.subnet-sap-admin[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_admin.is_existing ? var.databases[count.index].admin_nic.private_ip_address : lookup(var.databases[count.index].admin_nic, "private_ip_address", false) != false ? var.databases[count.index].admin_nic.private_ip_address : cidrhost(var.infrastructure.vnets.sap.subnet_admin.prefix, (count.index + 4))
    private_ip_address_allocation = "static"
  }
}

# Creates the DB traffic NIC and private IP address for HANA database nodes
resource "azurerm_network_interface" "nic-hdb-db" {
  count                         = length(var.databases)
  name                          = lookup(var.databases[count.index].db_nic, "name", false) != false ? var.databases[count.index].db_nic.name : "${var.databases[count.index].name}-db-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-db[0].id
  enable_accelerated_networking = true

  ip_configuration {
    primary                       = true
    name                          = "${var.databases[count.index].name}-db-nic-ip"
    subnet_id                     = var.subnet-sap-db[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_db.is_existing ? var.databases[count.index].db_nic.private_ip_address : lookup(var.databases[count.index].db_nic, "private_ip_address", false) != false ? var.databases[count.index].db_nic.private_ip_address : cidrhost(var.infrastructure.vnets.sap.subnet_db.prefix, (count.index + 4))
    private_ip_address_allocation = "static"
  }
}

# VIRTUAL MACHINES ================================================================================================

# Creates HANA database VM
resource "azurerm_virtual_machine" "vm-hdb" {
  count                         = length(var.databases)
  name                          = var.databases[count.index].name
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  primary_network_interface_id  = azurerm_network_interface.nic-hdb-db[count.index].id
  network_interface_ids         = [azurerm_network_interface.nic-hdb-admin[count.index].id, azurerm_network_interface.nic-hdb-db[count.index].id]
  vm_size                       = var.databases[count.index].size == "S" ? local.sizes.S.compute.vm_size : var.databases[count.index].size == "M" ? local.sizes.M.compute.vm_size : var.databases[count.index].size == "L" ? local.sizes.L.compute.vm_size : var.databases[count.index].size == "XL" ? local.sizes.XL.compute.vm_size : var.databases[count.index].size == "XXL" ? local.sizes.XXL.compute.vm_size : null
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.databases[count.index].name}-osdisk"
    caching           = var.databases[count.index].size == "S" ? local.sizes.S.storage.os.caching : var.databases[count.index].size == "M" ? local.sizes.M.storage.os.caching : var.databases[count.index].size == "L" ? local.sizes.L.storage.os.caching : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.os.caching : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.os.caching : null
    create_option     = "FromImage"
    managed_disk_type = var.databases[count.index].size == "S" ? local.sizes.S.storage.os.disk_type : var.databases[count.index].size == "M" ? local.sizes.M.storage.os.disk_type : var.databases[count.index].size == "L" ? local.sizes.L.storage.os.disk_type : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.os.disk_type : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.os.disk_type : null
    disk_size_gb      = var.databases[count.index].size == "S" ? local.sizes.S.storage.os.size_gb : var.databases[count.index].size == "M" ? local.sizes.M.storage.os.size_gb : var.databases[count.index].size == "L" ? local.sizes.L.storage.os.size_gb : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.os.size_gb : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.os.size_gb : null
  }


  storage_image_reference {
    publisher = var.databases[count.index].os.publisher
    offer     = var.databases[count.index].os.offer
    sku       = var.databases[count.index].os.sku
    version   = "latest"
  }

  dynamic "storage_data_disk" {
    iterator = disk
    for_each = var.databases[count.index].size == "S" ? range(local.sizes.S.storage.data_log.count) : var.databases[count.index].size == "M" ? range(local.sizes.M.storage.data_log.count) : var.databases[count.index].size == "L" ? range(local.sizes.L.storage.data_log.count) : var.databases[count.index].size == "XL" ? range(local.sizes.XL.storage.data_log.count) : var.databases[count.index].size == "XXL" ? range(local.sizes.XXL.storage.data_log.count) : []
    content {
      name                      = "${var.databases[count.index].name}-disk-data-log-${disk.value}"
      caching                   = var.databases[count.index].size == "S" ? local.sizes.S.storage.data_log.caching : var.databases[count.index].size == "M" ? local.sizes.M.storage.data_log.caching : var.databases[count.index].size == "L" ? local.sizes.L.storage.data_log.caching : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.data_log.caching : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.data_log.caching : null
      create_option             = "Empty"
      managed_disk_type         = var.databases[count.index].size == "S" ? local.sizes.S.storage.data_log.disk_type : var.databases[count.index].size == "M" ? local.sizes.M.storage.data_log.disk_type : var.databases[count.index].size == "L" ? local.sizes.L.storage.data_log.disk_type : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.data_log.disk_type : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.data_log.disk_type : null
      disk_size_gb              = var.databases[count.index].size == "S" ? local.sizes.S.storage.data_log.size_gb : var.databases[count.index].size == "M" ? local.sizes.M.storage.data_log.size_gb : var.databases[count.index].size == "L" ? local.sizes.L.storage.data_log.size_gb : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.data_log.size_gb : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.data_log.size_gb : null
      write_accelerator_enabled = var.databases[count.index].size == "S" ? local.sizes.S.storage.data_log.write_accelerator : var.databases[count.index].size == "M" ? local.sizes.M.storage.data_log.write_accelerator : var.databases[count.index].size == "L" ? local.sizes.L.storage.data_log.write_accelerator : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.data_log.write_accelerator : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.data_log.write_accelerator : null
      lun                       = disk.value
    }
  }

  dynamic "storage_data_disk" {
    iterator = disk
    for_each = var.databases[count.index].size == "S" ? range(local.sizes.S.storage.shared.count) : var.databases[count.index].size == "M" ? range(local.sizes.M.storage.shared.count) : var.databases[count.index].size == "L" ? range(local.sizes.L.storage.shared.count) : var.databases[count.index].size == "XL" ? range(local.sizes.XL.storage.shared.count) : var.databases[count.index].size == "XXL" ? range(local.sizes.XXL.storage.shared.count) : []
    content {
      name                      = "${var.databases[count.index].name}-disk-shared-${disk.value}"
      caching                   = var.databases[count.index].size == "S" ? local.sizes.S.storage.shared.caching : var.databases[count.index].size == "M" ? local.sizes.M.storage.shared.caching : var.databases[count.index].size == "L" ? local.sizes.L.storage.shared.caching : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.shared.caching : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.shared.caching : null
      create_option             = "Empty"
      managed_disk_type         = var.databases[count.index].size == "S" ? local.sizes.S.storage.shared.disk_type : var.databases[count.index].size == "M" ? local.sizes.M.storage.shared.disk_type : var.databases[count.index].size == "L" ? local.sizes.L.storage.shared.disk_type : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.shared.disk_type : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.shared.disk_type : null
      disk_size_gb              = var.databases[count.index].size == "S" ? local.sizes.S.storage.shared.size_gb : var.databases[count.index].size == "M" ? local.sizes.M.storage.shared.size_gb : var.databases[count.index].size == "L" ? local.sizes.L.storage.shared.size_gb : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.shared.size_gb : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.shared.size_gb : null
      write_accelerator_enabled = var.databases[count.index].size == "S" ? local.sizes.S.storage.shared.write_accelerator : var.databases[count.index].size == "M" ? local.sizes.M.storage.shared.write_accelerator : var.databases[count.index].size == "L" ? local.sizes.L.storage.shared.write_accelerator : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.shared.write_accelerator : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.shared.write_accelerator : null
      lun                       = disk.value + (var.databases[count.index].size == "S" ? local.sizes.S.storage.data_log.count : var.databases[count.index].size == "M" ? local.sizes.M.storage.data_log.count : var.databases[count.index].size == "L" ? local.sizes.L.storage.data_log.count : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.data_log.count : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.data_log.count : null)
    }
  }

  dynamic "storage_data_disk" {
    iterator = disk
    for_each = var.databases[count.index].size == "S" ? range(local.sizes.S.storage.sap.count) : var.databases[count.index].size == "M" ? range(local.sizes.M.storage.sap.count) : var.databases[count.index].size == "L" ? range(local.sizes.L.storage.sap.count) : var.databases[count.index].size == "XL" ? range(local.sizes.XL.storage.sap.count) : var.databases[count.index].size == "XXL" ? range(local.sizes.XXL.storage.sap.count) : []
    content {
      name                      = "${var.databases[count.index].name}-disk-sap-${disk.value}"
      caching                   = var.databases[count.index].size == "S" ? local.sizes.S.storage.sap.caching : var.databases[count.index].size == "M" ? local.sizes.M.storage.sap.caching : var.databases[count.index].size == "L" ? local.sizes.L.storage.sap.caching : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.sap.caching : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.sap.caching : null
      create_option             = "Empty"
      managed_disk_type         = var.databases[count.index].size == "S" ? local.sizes.S.storage.sap.disk_type : var.databases[count.index].size == "M" ? local.sizes.M.storage.sap.disk_type : var.databases[count.index].size == "L" ? local.sizes.L.storage.sap.disk_type : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.sap.disk_type : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.sap.disk_type : null
      disk_size_gb              = var.databases[count.index].size == "S" ? local.sizes.S.storage.sap.size_gb : var.databases[count.index].size == "M" ? local.sizes.M.storage.sap.size_gb : var.databases[count.index].size == "L" ? local.sizes.L.storage.sap.size_gb : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.sap.size_gb : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.sap.size_gb : null
      write_accelerator_enabled = var.databases[count.index].size == "S" ? local.sizes.S.storage.sap.write_accelerator : var.databases[count.index].size == "M" ? local.sizes.M.storage.sap.write_accelerator : var.databases[count.index].size == "L" ? local.sizes.L.storage.sap.write_accelerator : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.sap.write_accelerator : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.sap.write_accelerator : null
      lun                       = disk.value + (var.databases[count.index].size == "S" ? (local.sizes.S.storage.data_log.count + local.sizes.S.storage.shared.count) : var.databases[count.index].size == "M" ? (local.sizes.M.storage.data_log.count + local.sizes.M.storage.shared.count) : var.databases[count.index].size == "L" ? (local.sizes.L.storage.data_log.count + local.sizes.L.storage.shared.count) : var.databases[count.index].size == "XL" ? (local.sizes.XL.storage.data_log.count + local.sizes.XL.storage.shared.count) : var.databases[count.index].size == "XXL" ? (local.sizes.XXL.storage.data_log.count + local.sizes.XXL.storage.shared.count) : null)
    }
  }

  dynamic "storage_data_disk" {
    iterator = disk
    for_each = var.databases[count.index].size == "S" ? range(local.sizes.S.storage.backup.count) : var.databases[count.index].size == "M" ? range(local.sizes.M.storage.backup.count) : var.databases[count.index].size == "L" ? range(local.sizes.L.storage.backup.count) : var.databases[count.index].size == "XL" ? range(local.sizes.XL.storage.backup.count) : var.databases[count.index].size == "XXL" ? range(local.sizes.XXL.storage.backup.count) : []
    content {
      name                      = "${var.databases[count.index].name}-disk-backup-${disk.value}"
      caching                   = var.databases[count.index].size == "S" ? local.sizes.S.storage.backup.caching : var.databases[count.index].size == "M" ? local.sizes.M.storage.backup.caching : var.databases[count.index].size == "L" ? local.sizes.L.storage.backup.caching : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.backup.caching : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.backup.caching : null
      create_option             = "Empty"
      managed_disk_type         = var.databases[count.index].size == "S" ? local.sizes.S.storage.backup.disk_type : var.databases[count.index].size == "M" ? local.sizes.M.storage.backup.disk_type : var.databases[count.index].size == "L" ? local.sizes.L.storage.backup.disk_type : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.backup.disk_type : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.backup.disk_type : null
      disk_size_gb              = var.databases[count.index].size == "S" ? local.sizes.S.storage.backup.size_gb : var.databases[count.index].size == "M" ? local.sizes.M.storage.backup.size_gb : var.databases[count.index].size == "L" ? local.sizes.L.storage.backup.size_gb : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.backup.size_gb : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.backup.size_gb : null
      write_accelerator_enabled = var.databases[count.index].size == "S" ? local.sizes.S.storage.backup.write_accelerator : var.databases[count.index].size == "M" ? local.sizes.M.storage.backup.write_accelerator : var.databases[count.index].size == "L" ? local.sizes.L.storage.backup.write_accelerator : var.databases[count.index].size == "XL" ? local.sizes.XL.storage.backup.write_accelerator : var.databases[count.index].size == "XXL" ? local.sizes.XXL.storage.backup.write_accelerator : null
      lun                       = disk.value + (var.databases[count.index].size == "S" ? (local.sizes.S.storage.data_log.count + local.sizes.S.storage.shared.count + local.sizes.S.storage.sap.count) : var.databases[count.index].size == "M" ? (local.sizes.M.storage.data_log.count + local.sizes.M.storage.shared.count + local.sizes.M.storage.sap.count) : var.databases[count.index].size == "L" ? (local.sizes.L.storage.data_log.count + local.sizes.L.storage.shared.count + local.sizes.L.storage.sap.count) : var.databases[count.index].size == "XL" ? (local.sizes.XL.storage.data_log.count + local.sizes.XL.storage.shared.count + local.sizes.XL.storage.sap.count) : var.databases[count.index].size == "XXL" ? (local.sizes.XXL.storage.data_log.count + local.sizes.XXL.storage.shared.count + local.sizes.XXL.storage.sap.count) : null)
    }
  }

  os_profile {
    computer_name  = var.databases[count.index].name
    admin_username = var.databases[count.index].authentication.username
    admin_password = lookup(var.databases[count.index].authentication, "password", null)
  }

  os_profile_linux_config {
    disable_password_authentication = var.databases[count.index].authentication.type != "password" ? true : false
    dynamic "ssh_keys" {
      for_each = var.databases[count.index].authentication.type != "password" ? ["key"] : []
      content {
        path     = "/home/${var.databases[count.index].authentication.username}/.ssh/authorized_keys"
        key_data = file(var.databases[count.index].authentication.path_to_public_key)
      }
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = var.storageaccount-bootdiagnostics.primary_blob_endpoint
  }
}
