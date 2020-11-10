variable "resource_group" {
  description = "Details of the resource group"
}

variable "vnet_sap" {
  description = "Details of the SAP VNet"
}

variable "storage_bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

variable naming {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

variable "admin_subnet" {
  description = "Information about SAP admin subnet"
}

variable "db_subnet" {
  description = "Information about SAP db subnet"
}

variable "sid_kv_user" {
  description = "Details of the user keyvault for sap_system"
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

locals {
  // Imports database sizing information

  sizes = jsondecode(file(length(var.custom_disk_sizes_filename) > 0 ? var.custom_disk_sizes_filename : "${path.module}/../../../../../configs/hdb_sizes.json"))

  computer_names       = var.naming.virtualmachine_names.HANA_COMPUTERNAME
  virtualmachine_names = var.naming.virtualmachine_names.HANA_VMNAME

  storageaccount_names = var.naming.storageaccount_names.SDU
  resource_suffixes    = var.naming.resource_suffixes

  region = try(var.infrastructure.region, "")
  sid    = upper(try(var.application.sid, ""))
  prefix = try(var.infrastructure.resource_group.name, var.naming.prefix.SDU)

  rg_name = try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))

  // Retrieve information about Sap Landscape from tfstate file
  landscape_tfstate  = var.landscape_tfstate
  kv_landscape_id    = try(local.landscape_tfstate.landscape_key_vault_user_arm_id, "")
  secret_sid_pk_name = try(local.landscape_tfstate.sid_public_key_secret_name, "")

  // Define this variable to make it easier when implementing existing kv.
  sid_kv_user = try(var.sid_kv_user[0], null)

  # SAP vnet
  var_infra = try(var.infrastructure, {})

  hdb_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  enable_deployment = (length(local.hdb_list) > 0) ? true : false

  // Filter the list of databases to only HANA platform entries
  hdb = try(local.hdb_list[0], {})

  // Zones
  zones            = try(local.hdb.zones, [])
  zonal_deployment = length(local.zones) > 0 ? true : false
  db_zone_count    = length(local.zones)

  hdb_platform = try(local.hdb.platform, "NONE")
  hdb_version  = try(local.hdb.db_version, "2.00.043")
  // If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image = try(local.hdb.os.source_image_id, "") != "" ? true : false
  hdb_os = {
    "source_image_id" = local.hdb_custom_image ? local.hdb.os.source_image_id : ""
    "publisher"       = try(local.hdb.os.publisher, local.hdb_custom_image ? "" : "suse")
    "offer"           = try(local.hdb.os.offer, local.hdb_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.hdb.os.sku, local.hdb_custom_image ? "" : "gen1")
  }
  hdb_size = try(local.hdb.size, "Demo")
  hdb_fs   = try(local.hdb.filesystem, "xfs")
  hdb_ha   = try(local.hdb.high_availability, false)

  sid_auth_type        = try(local.hdb.authentication.type, "key")
  enable_auth_password = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key      = local.enable_deployment && local.sid_auth_type == "key"
  sid_auth_username    = try(local.hdb.authentication.username, "azureadm")
  sid_auth_password    = local.enable_auth_password ? try(local.hdb.authentication.password, random_password.password[0].result) : ""

  db_systemdb_password   = "db_systemdb_password"
  os_sidadm_password     = "os_sidadm_password"
  os_sapadm_password     = "os_sapadm_password"
  xsa_admin_password     = "xsa_admin_password"
  cockpit_admin_password = "cockpit_admin_password"
  ha_cluster_password    = "ha_cluster_password"

  hdb_auth = {
    "type"     = local.sid_auth_type
    "username" = local.sid_auth_username
    "password" = "hdb_vm_password"
  }

  node_count      = try(length(local.hdb.dbnodes), 1)
  db_server_count = local.hdb_ha ? local.node_count * 2 : local.node_count

  hdb_ins    = try(local.hdb.instance, {})
  hdb_sid    = try(local.hdb_ins.sid, local.sid) // HANA database sid from the Databases array for use as reference to LB/AS
  hdb_nr     = try(local.hdb_ins.instance_number, "01")
  components = merge({ hana_database = [] }, try(local.hdb.components, {}))
  xsa        = try(local.hdb.xsa, { routing = "ports" })
  shine      = try(local.hdb.shine, { email = "shinedemo@microsoft.com" })

  dbnodes = flatten([[for idx, dbnode in try(local.hdb.dbnodes, [{}]) : {
    name         = try("${dbnode.name}-0", format("%s%s%s%s", local.prefix, var.naming.separator, local.virtualmachine_names[idx], local.resource_suffixes.vm))
    computername = try("${dbnode.name}-0", local.computer_names[idx], local.resource_suffixes.vm)
    role         = try(dbnode.role, "worker")
    admin_nic_ip = lookup(dbnode, "admin_nic_ips", [false, false])[0]
    db_nic_ip    = lookup(dbnode, "db_nic_ips", [false, false])[0]
    }
    ],
    [for idx, dbnode in try(local.hdb.dbnodes, [{}]) : {
      name         = try("${dbnode.name}-1", format("%s%s%s%s", local.prefix, var.naming.separator, local.virtualmachine_names[idx + local.node_count], local.resource_suffixes.vm))
      computername = try("${dbnode.name}-1", local.computer_names[idx + local.node_count])
      role         = try(dbnode.role, "worker")
      admin_nic_ip = lookup(dbnode, "admin_nic_ips", [false, false])[1]
      db_nic_ip    = lookup(dbnode, "db_nic_ips", [false, false])[1]
      } if local.hdb_ha
    ]
    ]
  )

  loadbalancer = try(local.hdb.loadbalancer, {})

  // Update HANA database information with defaults
  hana_database = merge(local.hdb,
    { platform = local.hdb_platform },
    { db_version = local.hdb_version },
    { os = local.hdb_os },
    { size = local.hdb_size },
    { filesystem = local.hdb_fs },
    { high_availability = local.hdb_ha },
    { authentication = local.hdb_auth },
    { instance = {
      sid             = local.hdb_sid,
      instance_number = local.hdb_nr
      }
    },
    { credentials = {
      db_systemdb_password   = local.db_systemdb_password,
      os_sidadm_password     = local.os_sidadm_password,
      os_sapadm_password     = local.os_sapadm_password,
      xsa_admin_password     = local.xsa_admin_password,
      cockpit_admin_password = local.cockpit_admin_password,
      ha_cluster_password    = local.ha_cluster_password
      }
    },
    { components = local.components },
    { xsa = local.xsa },
    { shine = local.shine },
    { dbnodes = local.dbnodes },
    { loadbalancer = local.loadbalancer }
  )

  // SAP SID used in HDB resource naming convention
  sap_sid = try(var.application.sid, local.sid)

  // Numerically indexed Hash of HANA DB nodes to be created
  hdb_vms = [
    for idx, dbnode in local.dbnodes : {
      platform       = local.hdb_platform,
      name           = dbnode.name
      computername   = dbnode.computername
      admin_nic_ip   = dbnode.admin_nic_ip,
      db_nic_ip      = dbnode.db_nic_ip,
      size           = local.hdb_size,
      os             = local.hdb_os,
      authentication = local.hdb_auth
      sid            = local.hdb_sid
    }
  ]

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  hdb_ip_offsets = {
    hdb_lb       = 4
    hdb_admin_vm = 10
    hdb_db_vm    = 10
  }

  // Ports used for specific HANA Versions
  lb_ports = {
    "1" = [
      "30015",
      "30017",
    ]

    "2" = [
      "30013",
      "30014",
      "30015",
      "30040",
      "30041",
      "30042",
    ]
  }

  loadbalancer_ports = flatten([
    for port in local.lb_ports[split(".", local.hdb_version)[0]] : {
      sid  = local.sap_sid
      port = tonumber(port) + (tonumber(local.hana_database.instance.instance_number) * 100)
    }
  ])

  // List of data disks to be created for HANA DB nodes
  data_disk_per_dbnode = (length(local.hdb_vms) > 0) ? flatten(
    [
      for storage_type in lookup(local.sizes, local.hdb_size).storage : [
        for disk_count in range(storage_type.count) : {
          suffix               = format("%s%02d", storage_type.name, disk_count)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
    ]
  ) : []

  data_disk_list = flatten([
    for vm_counter, hdb_vm in local.hdb_vms : [
      for idx, datadisk in local.data_disk_per_dbnode : {
        vm_index                  = vm_counter
        name                      = format("%s-%s", hdb_vm.name, datadisk.suffix)
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = idx
      }
    ]
  ])

  storage_list = lookup(local.sizes, local.hdb_size).storage
  enable_ultradisk = try(compact([
    for storage in local.storage_list :
    storage.disk_type == "UltraSSD_LRS" ? true : ""
  ])[0], false)
}
