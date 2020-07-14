/*-----------------------------------------------------------------------------8
|                                                                              |
|                                 HANA - VMs                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/

# NICS ============================================================================================================

/*-----------------------------------------------------------------------------8
HANA DB Linux Server private IP range: .10 -
+--------------------------------------4--------------------------------------*/

# Creates the admin traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "nics-dbnodes-admin" {
  count                         = local.enable_deployment ? length(local.hdb_vms) : 0
  name                          = "${local.hdb_vms[count.index].name}-admin-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${local.hdb_vms[count.index].name}-admin-nic-ip"
    subnet_id                     = local.sub_admin_exists ? data.azurerm_subnet.subnet-sap-admin[0].id : azurerm_subnet.subnet-sap-admin[0].id
    private_ip_address            = local.sub_admin_exists ? local.hdb_vms[count.index].admin_nic_ip : lookup(local.hdb_vms[count.index], "admin_nic_ip", false) != false ? local.hdb_vms[count.index].admin_nic_ip : cidrhost(local.sub_admin_prefix, tonumber(count.index) + 10)
    private_ip_address_allocation = "static"
  }
}

# Creates the DB traffic NIC and private IP address for database nodes
resource "azurerm_network_interface" "nics-dbnodes-db" {
  count                         = local.enable_deployment ? length(local.hdb_vms) : 0
  name                          = "${local.hdb_vms[count.index].name}-db-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary                       = true
    name                          = "${local.hdb_vms[count.index].name}-db-nic-ip"
    subnet_id                     = local.sub_db_exists ? data.azurerm_subnet.subnet-sap-db[0].id : azurerm_subnet.subnet-sap-db[0].id
    private_ip_address            = local.sub_db_exists ? local.hdb_vms[count.index].db_nic_ip : lookup(local.hdb_vms[count.index], "db_nic_ip", false) != false ? local.hdb_vms[count.index].db_nic_ip : cidrhost(local.sub_db_prefix, tonumber(count.index) + 10)
    private_ip_address_allocation = "static"
  }
}

# LOAD BALANCER ===================================================================================================

/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "hdb" {
  count               = local.enable_deployment ? 1 : 0
  name                = "${upper(local.sap_sid)}_hdb-alb"
  resource_group_name = var.resource-group[0].name
  location            = var.resource-group[0].location

  frontend_ip_configuration {
    name                          = "${upper(local.sap_sid)}_hdb-feip"
    subnet_id                     = local.sub_db_exists ? data.azurerm_subnet.subnet-sap-db[0].id : azurerm_subnet.subnet-sap-db[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.sub_db_exists ? try(local.hana_database.loadbalancer.frontend_ip, cidrhost(local.sub_db_prefix, tonumber(count.index) + 4)) : cidrhost(local.sub_db_prefix, tonumber(count.index) + 4)
  }
}

resource "azurerm_lb_backend_address_pool" "hdb" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.hdb[count.index].id
  name                = "${upper(local.sap_sid)}_hdbAlb-bePool"
}

resource "azurerm_lb_probe" "hdb" {
  count               = local.enable_deployment ? 1 : 0
  resource_group_name = var.resource-group[0].name
  loadbalancer_id     = azurerm_lb.hdb[count.index].id
  name                = "${upper(local.sap_sid)}Alb-hp"
  port                = "625${local.hana_database.instance.instance_number}"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# TODO:
# Current behavior, it will try to add all VMs in the cluster into the backend pool, which would not work since we do not have availability sets created yet.
# In a scale-out scenario, we need to rewrite this code according to the scale-out + HA reference architecture.
resource "azurerm_network_interface_backend_address_pool_association" "hdb" {
  count                   = local.enable_deployment ? length(azurerm_network_interface.nics-dbnodes-db) : 0
  network_interface_id    = azurerm_network_interface.nics-dbnodes-db[count.index].id
  ip_configuration_name   = azurerm_network_interface.nics-dbnodes-db[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.hdb[0].id
}

resource "azurerm_lb_rule" "hdb" {
  count                          = local.enable_deployment ? length(local.loadbalancer_ports) : 0
  resource_group_name            = var.resource-group[0].name
  loadbalancer_id                = azurerm_lb.hdb[0].id
  name                           = "${upper(local.loadbalancer_ports[count.index].sid)}_HDB_${local.loadbalancer_ports[count.index].port}"
  protocol                       = "Tcp"
  frontend_port                  = local.loadbalancer_ports[count.index].port
  backend_port                   = local.loadbalancer_ports[count.index].port
  frontend_ip_configuration_name = "${upper(local.loadbalancer_ports[count.index].sid)}_hdb-feip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.hdb[0].id
  probe_id                       = azurerm_lb_probe.hdb[0].id
  enable_floating_ip             = true
}

# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "hdb" {
  count                        = local.enable_deployment ? 1 : 0
  name                         = "${upper(local.sap_sid)}_hdb-avset"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  managed                      = true
}

# VIRTUAL MACHINES ================================================================================================

# Creates managed data disk
resource "azurerm_managed_disk" "data-disk" {
  count                = local.enable_deployment ? length(local.data-disk-list) : 0
  name                 = local.data-disk-list[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.data-disk-list[count.index].storage_account_type
  disk_size_gb         = local.data-disk-list[count.index].disk_size_gb
}

# Manages Linux Virtual Machine for HANA DB servers
resource "azurerm_linux_virtual_machine" "vm-dbnode" {
  count                        = local.enable_deployment ? length(local.hdb_vms) : 0
  name                         = local.hdb_vms[count.index].name
  computer_name                = replace(local.hdb_vms[count.index].name, "_", "")
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.hdb[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.nics-dbnodes-admin[count.index].id,
    azurerm_network_interface.nics-dbnodes-db[count.index].id
  ]
  size                            = lookup(local.sizes, local.hdb_vms[count.index].size).compute.vm_size
  admin_username                  = local.hdb_vms[count.index].authentication.username
  admin_password                  = lookup(local.hdb_vms[count.index].authentication, "password", null)
  disable_password_authentication = local.hdb_vms[count.index].authentication.type != "password" ? true : false

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten([for storage_type in lookup(local.sizes, local.hdb_vms[count.index].size).storage : [for disk_count in range(storage_type.count) : { name = storage_type.name, id = disk_count, disk_type = storage_type.disk_type, size_gb = storage_type.size_gb, caching = storage_type.caching }] if storage_type.name == "os"])
    content {
      name                 = "${local.hdb_vms[count.index].name}-osdisk"
      caching              = disk.value.caching
      storage_account_type = disk.value.disk_type
      disk_size_gb         = disk.value.size_gb
    }
  }

  source_image_id = local.hdb_vms[count.index].os.source_image_id != "" ? local.hdb_vms[count.index].os.source_image_id : null

  # If source_image_id is not defined, deploy with source_image_reference
  dynamic "source_image_reference" {
    for_each = range(local.hdb_vms[count.index].os.source_image_id == "" ? 1 : 0)
    content {
      publisher = local.hdb_vms[count.index].os.publisher
      offer     = local.hdb_vms[count.index].os.offer
      sku       = local.hdb_vms[count.index].os.sku
      version   = "latest"
    }
  }

  admin_ssh_key {
    username   = local.hdb_vms[count.index].authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Manages attaching a Disk to a Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "vm-dbnode-data-disk" {
  count                     = local.enable_deployment ? length(local.data-disk-list) : 0
  managed_disk_id           = azurerm_managed_disk.data-disk[count.index].id
  virtual_machine_id        = azurerm_linux_virtual_machine.vm-dbnode[floor(count.index / length(local.data-disk-per-dbnode))].id
  caching                   = local.data-disk-list[count.index].caching
  write_accelerator_enabled = local.data-disk-list[count.index].write_accelerator_enabled
  lun                       = count.index
}
