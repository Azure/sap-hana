variable "resource-group" {
  description = "Details of the resource group"
}

variable "subnet-mgmt" {
  description = "Details of the management subnet"
}

variable "nsg-mgmt" {
  description = "Details of the NSG for management subnet"
}

variable "vnet-sap" {
  description = "Details of the SAP VNet"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

# Set defaults
locals {

  # Admin subnet
  var_sub_admin    = try(var.infrastructure.vnets.sap.subnet_admin, {})
  sub_admin_exists = try(local.var_sub_admin.is_existing, false)
  sub_admin_arm_id = local.sub_admin_exists ? try(local.var_sub_admin.arm_id, "") : ""
  sub_admin_name   = local.sub_admin_exists ? "" : try(local.var_sub_admin.name, "subnet-admin")
  sub_admin_prefix = local.sub_admin_exists ? "" : try(local.var_sub_admin.prefix, "10.1.1.0/24")

  # Admin NSG
  var_sub_admin_nsg    = try(var.infrastructure.vnets.sap.subnet_admin.nsg, {})
  sub_admin_nsg_exists = try(local.var_sub_admin_nsg.is_existing, false)
  sub_admin_nsg_arm_id = local.sub_admin_nsg_exists ? try(local.var_sub_admin_nsg.arm_id, "") : ""
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? "" : try(local.var_sub_admin_nsg.name, "nsg-admin")

  # DB subnet
  var_sub_db    = try(var.infrastructure.vnets.sap.subnet_db, {})
  sub_db_exists = try(local.var_sub_db.is_existing, false)
  sub_db_arm_id = local.sub_db_exists ? try(local.var_sub_db.arm_id, "") : ""
  sub_db_name   = local.sub_db_exists ? "" : try(local.var_sub_db.name, "subnet-db")
  sub_db_prefix = local.sub_db_exists ? "" : try(local.var_sub_db.prefix, "10.1.2.0/24")

  # DB NSG
  var_sub_db_nsg    = try(var.infrastructure.vnets.sap.subnet_db.nsg, {})
  sub_db_nsg_exists = try(local.var_sub_db_nsg.is_existing, false)
  sub_db_nsg_arm_id = local.sub_db_nsg_exists ? try(local.var_sub_db_nsg.arm_id, "") : ""
  sub_db_nsg_name   = local.sub_db_nsg_exists ? "" : try(local.var_sub_db_nsg.name, "nsg-db")

  hdb_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]
  enable_deployment = (length(local.hdb_list) > 0) ? true : false

  # Filter the list of databases to only HANA platform entries
  hdb          = try(local.hdb_list[0], {})
  hdb_platform = try(local.hdb.platform, "NONE")
  hdb_version  = try(local.hdb.db_version, "2.00.043")
  # If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image = try(local.hdb.os.source_image_id, "") != "" ? true : false
  hdb_os = {
    "source_image_id" = local.hdb_custom_image ? local.hdb.os.source_image_id : ""
    "publisher"       = try(local.hdb.os.publisher, local.hdb_custom_image ? "" : "suse")
    "offer"           = try(local.hdb.os.offer, local.hdb_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.hdb.os.sku, local.hdb_custom_image ? "" : "gen1")
  }
  hdb_size = try(local.hdb.size, "Demo")
  hdb_fs   = try(local.hdb.filesystem, "xfs")
  hdb_ha   = try(local.hdb.high_availability, "false")
  hdb_auth = try(local.hdb.authentication,
    {
      "type"     = "key"
      "username" = "azureadm"
  })
  hdb_ins = try(local.hdb.instance, {})
  # HANA database sid from the Databases array for use as reference to LB/AS
  hdb_sid                = try(local.hdb_ins.sid, "HN1")
  hdb_nr                 = try(local.hdb_ins.instance_number, "01")
  hdb_cred               = try(local.hdb.credentials, {})
  db_systemdb_password   = try(local.hdb_cred.db_systemdb_password, "")
  os_sidadm_password     = try(local.hdb_cred.os_sidadm_password, "")
  os_sapadm_password     = try(local.hdb_cred.os_sapadm_password, "")
  xsa_admin_password     = try(local.hdb_cred.xsa_admin_password, "")
  cockpit_admin_password = try(local.hdb_cred.cockpit_admin_password, "")
  ha_cluster_password    = try(local.hdb_cred.ha_cluster_password, "")
  components             = merge({ hana_database = [] }, try(local.hdb.components, {}))
  xsa                    = try(local.hdb.xsa, { routing = "ports" })
  shine                  = try(local.hdb.shine, { email = "shinedemo@microsoft.com" })

  dbnodes = [for idx, dbnode in try(local.hdb.dbnodes, []) : {
    "name" = try(dbnode.name, format("%s_%s_hdb%02d", local.sap_sid, local.hdb_sid, idx)),
    "role" = try(dbnode.role, "worker")
    }
  ]

  loadbalancer = try(local.hdb.loadbalancer, {})

  # Update HANA database information with defaults
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

  # SAP SID used in HDB resource naming convention
  sap_sid = try(var.application.sid, "HN1")

}

# Imports HANA database sizing information
locals {
  sizes = jsondecode(file("${path.root}/../hdb_sizes.json"))
}

locals {
  # Numerically indexed Hash of HANA DB nodes to be created
  hdb_vms = flatten([
    [
      for dbnode in local.hana_database.dbnodes : {
        platform       = local.hana_database.platform,
        name           = "${dbnode.name}-0",
        admin_nic_ip   = lookup(dbnode, "admin_nic_ips", [false, false])[0],
        db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[0],
        size           = local.hana_database.size,
        os             = local.hana_database.os,
        authentication = local.hana_database.authentication
        sid            = local.hana_database.instance.sid
      }
    ],
    [
      for dbnode in local.hana_database.dbnodes : {
        platform       = local.hana_database.platform,
        name           = "${dbnode.name}-1",
        admin_nic_ip   = lookup(dbnode, "admin_nic_ips", [false, false])[1],
        db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[1],
        size           = local.hana_database.size,
        os             = local.hana_database.os,
        authentication = local.hana_database.authentication
        sid            = local.hana_database.instance.sid
      }
      if local.hana_database.high_availability
    ]
  ])

  # Ports used for specific HANA Versions
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
    for port in local.lb_ports[split(".", local.hana_database.db_version)[0]] : {
      sid  = local.sap_sid
      port = tonumber(port) + (tonumber(local.hana_database.instance.instance_number) * 100)
    }
  ])
}

# List of data disks to be created for HANA DB nodes
locals {
  data-disk-per-dbnode = flatten(
    length(local.hdb_vms) > 0 ?
    [
      for storage_type in lookup(local.sizes, local.hdb_vms[0].size).storage : [
        for disk_count in range(storage_type.count) : {
          name                      = join("-", [storage_type.name, disk_count])
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ] : [])

  data-disk-list = flatten([
    for hdb_vm in local.hdb_vms : [
      for datadisk in local.data-disk-per-dbnode : {
        name                      = join("-", [hdb_vm.name, datadisk.name])
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
      }
    ]
  ])
}
