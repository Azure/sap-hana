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

variable "random-id" {
  description = "Random hex string"
}

variable "deployer-uai" {
  description = "Details of the UAI used by deployer(s)"
}

variable "deployer_user"{
  description = "Details of the users"
}

variable "region_mapping" {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"

  // 28 Regions 

  default = {
    westus             = "weus"
    westus2            = "wus2"
    centralus          = "ceus"
    eastus             = "eaus"
    eastus2            = "eus2"
    northcentralus     = "ncus"
    southcentralus     = "scus"
    westcentralus      = "wcus"
    northeurope        = "noeu"
    westeurope         = "weeu"
    eastasia           = "eaas"
    southeastasia      = "seas"
    brazilsouth        = "brso"
    japaneast          = "jpea"
    japanwest          = "jpwe"
    centralindia       = "cein"
    southindia         = "soin"
    westindia          = "wein"
    uksouth2           = "uks2"
    uknorth            = "ukno"
    canadacentral      = "cace"
    canadaeast         = "caea"
    australiaeast      = "auea"
    australiasoutheast = "ause"
    uksouth            = "ukso"
    ukwest             = "ukwe"
    koreacentral       = "koce"
    koreasouth         = "koso"
  }
}

// Set defaults
locals {
  region         = try(var.infrastructure.region, "")
  environment    = lower(try(var.infrastructure.environment, ""))
  sid            = upper(try(var.application.sid, ""))
  codename       = lower(try(var.infrastructure.codename, ""))
  location_short = lower(try(var.region_mapping[local.region], "unkn"))
  // Using replace "--" with "-" and "_-" with "-" in case of one of the components like codename is empty
  prefix    = try(local.var_infra.resource_group.name, upper(replace(replace(format("%s-%s-%s_%s-%s", local.environment, local.location_short, substr(local.vnet_sap_name_prefix, 0, 7), local.codename, local.sid), "_-", "-"), "--", "-")))
  sa_prefix = lower(replace(format("%s%s%sdiag", substr(local.environment, 0, 5), local.location_short, substr(local.codename, 0, 7)), "--", "-"))
  rg_name   = local.prefix

  // Post fix for all deployed resources
  postfix = random_id.sapsystem.hex
  
  // key vault for sap system
  kv_prefix       = upper(format("%s%s%s", substr(local.environment, 0, 5), local.location_short, substr(local.vnet_sap_name_prefix, 0, 7)))
  kv_private_name = format("%sSIDp%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))
  kv_user_name    = format("%sSIDu%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))
  kv_users        = [var.deployer_user]
  enable_auth_password = local.enable_deployment && local.hdb_auth.type == "password"
  sid_auth_username    = local.hdb_auth.username
  sid_auth_password    = local.enable_auth_password ? try(local.hdb_auth.password, random_password.password[0].result) : null
  
  # SAP vnet
  var_infra       = try(var.infrastructure, {})
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, "")
  vnet_nr_parts   = length(split("-", local.vnet_sap_name))
  // Default naming of vnet has multiple parts. Taking the second-last part as the name 
  vnet_sap_name_prefix = try(substr(upper(local.vnet_sap_name), -5, 5), "") == "-VNET" ? split("-", local.vnet_sap_name)[(local.vnet_nr_parts -2)] : local.vnet_sap_name

  // Admin subnet
  var_sub_admin    = try(var.infrastructure.vnets.sap.subnet_admin, {})
  sub_admin_arm_id = try(local.var_sub_admin.arm_id, "")
  sub_admin_exists = length(local.sub_admin_arm_id) > 0 ? true : false
  sub_admin_name   = local.sub_admin_exists ? try(split("/", local.sub_admin_arm_id)[10], "") : try(local.var_sub_admin.name, format("%s_admin-subnet", local.prefix))
  sub_admin_prefix = try(local.var_sub_admin.prefix, "")

  // Admin NSG
  var_sub_admin_nsg    = try(var.infrastructure.vnets.sap.subnet_admin.nsg, {})
  sub_admin_nsg_exists = try(local.var_sub_admin_nsg.is_existing, false)
  sub_admin_nsg_arm_id = local.sub_admin_nsg_exists ? try(local.var_sub_admin_nsg.arm_id, "") : ""
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? try(split("/", local.sub_admin_nsg_arm_id)[8], "") : try(local.var_sub_admin_nsg.name, format("%s_adminSubnet-nsg", local.prefix))

  // DB subnet
  var_sub_db    = try(var.infrastructure.vnets.sap.subnet_db, {})
  sub_db_arm_id = try(local.var_sub_db.arm_id, "")
  sub_db_exists = length(local.sub_db_arm_id) > 0 ? true : false
  sub_db_name   = local.sub_db_exists ? try(split("/", local.sub_db_arm_id)[10], "") : try(local.var_sub_db.name, format("%s_db-subnet", local.prefix))
  sub_db_prefix = try(local.var_sub_db.prefix, "")

  // DB NSG
  var_sub_db_nsg    = try(var.infrastructure.vnets.sap.subnet_db.nsg, {})
  sub_db_nsg_exists = try(local.var_sub_db_nsg.is_existing, false)
  sub_db_nsg_arm_id = local.sub_db_nsg_exists ? try(local.var_sub_db_nsg.arm_id, "") : ""
  sub_db_nsg_name   = local.sub_db_nsg_exists ? try(split("/", local.sub_db_nsg_arm_id)[8], "") : try(local.var_sub_db_nsg.name, format("%s_dbSubnet-nsg", local.prefix))

  hdb_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  enable_deployment = (length(local.hdb_list) > 0) ? true : false

  // Filter the list of databases to only HANA platform entries
  hdb          = try(local.hdb_list[0], {})
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
  hdb_auth = try(local.hdb.authentication,
    {
      "type"     = "key"
      "username" = "azureadm"
  })

  hdb_ins                = try(local.hdb.instance, {})
  hdb_sid                = try(local.hdb_ins.sid, local.sid) // HANA database sid from the Databases array for use as reference to LB/AS
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

  customer_provided_names = try(local.hdb.dbnodes[0].name, "") == "" ? false : true

  dbnodes = flatten([[for idx, dbnode in try(local.hdb.dbnodes, [{}]) : {
    name         = try("${dbnode.name}-0", format("%sd%s%02dl%d%s", lower(local.sap_sid), lower(local.hdb_sid), idx, 0, substr(var.random-id.hex, 0, 3))),
    role         = try(dbnode.role, "worker"),
    admin_nic_ip = lookup(dbnode, "admin_nic_ips", [false, false])[0],
    db_nic_ip    = lookup(dbnode, "db_nic_ips", [false, false])[0]
    }
    ],
    [for idx, dbnode in try(local.hdb.dbnodes, [{}]) : {
      name         = try("${dbnode.name}-1", format("%sd%s%02dl%d%s", lower(local.sap_sid), lower(local.hdb_sid), idx, 1, substr(var.random-id.hex, 0, 3)))
      role         = try(dbnode.role, "worker")
      admin_nic_ip = lookup(dbnode, "admin_nic_ips", [false, false])[1],
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

  // Imports HANA database sizing information
  sizes = jsondecode(file("${path.module}/../../../../../configs/hdb_sizes.json"))

  // Numerically indexed Hash of HANA DB nodes to be created
  hdb_vms = [
    for idx, dbnode in local.dbnodes : {
      platform       = local.hdb_platform,
      name           = dbnode.name
      admin_nic_ip   = dbnode.admin_nic_ip,
      db_nic_ip      = dbnode.db_nic_ip,
      size           = local.hdb_size,
      os             = local.hdb_os,
      authentication = local.hdb_auth
      sid            = local.hdb_sid
    }
  ]

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
  data-disk-per-dbnode = (length(local.hdb_vms) > 0) ? flatten(
    [
      for storage_type in lookup(local.sizes, local.hdb_size).storage : [
        for disk_count in range(storage_type.count) : {
          suffix                    = format("%s%02d", storage_type.name, disk_count)
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
    ]
  ) : []

  data-disk-list = flatten([
    for hdb_vm in local.hdb_vms : [
      for datadisk in local.data-disk-per-dbnode : {
        name                      = local.customer_provided_names ? format("%s-%s", hdb_vm.name, datadisk.suffix) : format("%s_%s-%s", local.prefix, hdb_vm.name, datadisk.suffix)
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
      }
    ]
  ])
}
