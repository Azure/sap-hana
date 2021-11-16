variable "anchor_vm" {
  description = "Deployed anchor VM"
}

variable "resource_group" {
  description = "Details of the resource group"
}

variable "storage_bootdiag_endpoint" {
  description = "Details of the boot diagnostics storage account"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

variable "naming" {
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
variable "sid_kv_user_id" {
  description = "ID of the user keyvault for sap_system"
}

variable "sdu_public_key" {
  description = "Public key used for authentication"
}

variable "sid_password" {
  description = "SDU password"
}

variable "sid_username" {
  description = "SDU username"
}

variable "sap_sid" {
  description = "The SID of the application"
}

variable "db_asg_id" {
  description = "Database Application Security Group"
}

variable "deployment" {
  description = "The type of deployment"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
}

variable "cloudinit_growpart_config" {
  description = "A cloud-init config that configures automatic growpart expansion of root partition"
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""

}

variable "use_loadbalancers_for_standalone_deployments" {
  description = "Defines if load balancers are used even for standalone deployments"
  default     = true
}

variable "database_vm_names" {
  default = [""]
}

variable "database_vm_db_nic_ips" {
  default = [""]
}

variable "database_vm_admin_nic_ips" {
  default = [""]
}

variable "database_vm_storage_nic_ips" {
  default = [""]
}

variable "database_server_count" {
  default = 1
}

variable   "order_deployment" {
  description = "psuedo condition for ordering deployment"
  default     = ""
}

locals {
  // Imports database sizing information

  default_filepath = format("%s%s", path.module, "/../../../../../configs/anydb_sizes.json")
  custom_sizing    = length(var.custom_disk_sizes_filename) > 0

  // Imports database sizing information
  file_name = local.custom_sizing ? (
    fileexists(var.custom_disk_sizes_filename) ? (
      var.custom_disk_sizes_filename) : (
      format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
    )) : (
    local.default_filepath

  )

  sizes = jsondecode(file(local.file_name))

  faults = jsondecode(file(format("%s%s", path.module, "/../../../../../configs/max_fault_domain_count.json")))

  storageaccount_names = var.naming.storageaccount_names.SDU
  resource_suffixes    = var.naming.resource_suffixes

  region    = var.infrastructure.region
  anydb_sid = (length(local.anydb_databases) > 0) ? try(local.anydb.instance.sid, lower(substr(local.anydb_platform, 0, 3))) : lower(substr(local.anydb_platform, 0, 3))
  sid       = length(var.sap_sid) > 0 ? var.sap_sid : local.anydb_sid
  prefix    = trimspace(var.naming.prefix.SDU)
  rg_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    coalesce(try(var.infrastructure.resource_group.name, ""), format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))
  )

  //Allowing changing the base for indexing, default is zero-based indexing, if customers want the first disk to start with 1 they would change this
  offset = try(var.options.resource_offset, 0)

  //Allowing to keep the old nic order
  legacy_nic_order = try(var.options.legacy_nic_order, false)
  // Availability Set 
  availabilityset_arm_ids = try(local.anydb.avset_arm_ids, [])
  availabilitysets_exist  = length(local.availabilityset_arm_ids) > 0 ? true : false

  // Return the max fault domain count for the region
  faultdomain_count = try(tonumber(compact(
    [for pair in local.faults :
      upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
  ])[0]), 2)


  // Dual network cards
  anydb_dual_nics = try(local.anydb.dual_nics, false)

  // Filter the list of databases to only AnyDB platform entries
  // Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb_databases = [
    for database in var.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  enable_deployment = (length(local.anydb_databases) > 0) ? true : false

  anydb          = local.enable_deployment ? local.anydb_databases[0] : null
  anydb_platform = local.enable_deployment ? try(local.anydb.platform, "NONE") : "NONE"
  // Enable deployment based on length of local.anydb_databases

  // If custom image is used, we do not overwrite os reference with default value
  anydb_custom_image = try(local.anydb.os.source_image_id, "") != "" ? true : false

  anydb_ostype = upper(local.anydb_platform) == "SQLSERVER" ? "WINDOWS" : try(local.anydb.os.os_type, "LINUX")
  anydb_oscode = upper(local.anydb_ostype) == "LINUX" ? "l" : "w"
  anydb_size   = try(local.anydb.size, "Default")

  db_sizing = local.enable_deployment ? lookup(local.sizes.db, local.anydb_size).storage : []
  db_size   = local.enable_deployment ? lookup(local.sizes.db, local.anydb_size).compute : {}

  anydb_sku = try(local.db_size.vm_size, "Standard_E4s_v3")

  anydb_fs = try(local.anydb.filesystem, "xfs")
  anydb_ha = try(local.anydb.high_availability, false)

  db_sid       = lower(substr(local.anydb_platform, 0, 3))
  loadbalancer = try(local.anydb.loadbalancer, {})
  enable_db_lb_deployment = var.database_server_count > 0 && (var.use_loadbalancers_for_standalone_deployments || var.database_server_count > 1)

  anydb_cred = try(local.anydb.credentials, {})

  sid_auth_type        = try(local.anydb.authentication.type, "key")
  enable_auth_password = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key      = local.enable_deployment && local.sid_auth_type == "key"

  // Tags
  tags = try(local.anydb.tags, {})

  authentication = {
    "type"     = local.sid_auth_type
    "username" = var.sid_username
    "password" = var.sid_password
  }

  // Default values in case not provided
  os_defaults = {
    ORACLE = {
      "publisher" = "Oracle",
      "offer"     = "Oracle-Linux",
      "sku"       = "77",
      "version"   = "latest"
    }
    DB2 = {
      "publisher" = "SUSE",
      "offer"     = "sles-sap-12-sp5",
      "sku"       = "gen1"
      "version"   = "latest"
    }
    ASE = {
      "publisher" = "SUSE",
      "offer"     = "sles-sap-12-sp5",
      "sku"       = "gen1"
      "version"   = "latest"
    }
    SQLSERVER = {
      "publisher" = "MicrosoftSqlServer",
      "offer"     = "SQL2017-WS2016",
      "sku"       = "standard-gen2",
      "version"   = "latest"
    }
    NONE = {
      "publisher" = "",
      "offer"     = "",
      "sku"       = "",
      "version"   = ""
    }
  }

  anydb_os = {
    "source_image_id" = local.anydb_custom_image ? local.anydb.os.source_image_id : ""
    "publisher"       = try(local.anydb.os.publisher, local.anydb_custom_image ? "" : local.os_defaults[upper(local.anydb_platform)].publisher)
    "offer"           = try(local.anydb.os.offer, local.anydb_custom_image ? "" : local.os_defaults[upper(local.anydb_platform)].offer)
    "sku"             = try(local.anydb.os.sku, local.anydb_custom_image ? "" : local.os_defaults[upper(local.anydb_platform)].sku)
    "version"         = try(local.anydb.os.version, local.anydb_custom_image ? "" : local.os_defaults[upper(local.anydb_platform)].version)
  }

  //Observer VM
  observer                 = try(local.anydb.observer, {})
  deploy_observer          = upper(local.anydb_platform) == "ORACLE" && local.anydb_ha
  observer_size            = "Standard_D4s_v3"
  observer_authentication  = local.authentication
  observer_custom_image    = local.anydb_custom_image
  observer_custom_image_id = local.anydb_os.source_image_id
  observer_os              = local.anydb_os

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  anydb_ip_offsets = {
    anydb_lb       = 4
    anydb_admin_vm = 4
    anydb_db_vm    = 5 + 1
    observer_db_vm = 5
  }

  // Ports used for specific DB Versions
  lb_ports = {
    "ASE" = [
      "1433"
    ]
    "ORACLE" = [
      "1521"
    ]
    "DB2" = [
      "62500"
    ]
    "SQLSERVER" = [
      "59999"
    ]
    "NONE" = [
      "80"
    ]
  }

  loadbalancer_ports = flatten([
    for port in local.lb_ports[upper(local.anydb_platform)] : {
      port = tonumber(port)
    }
  ])

  // OS disk to be created for DB nodes
  // disk_iops_read_write only apply for ultra
  os_disk = flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = try(storage_type.write_accelerator, false)
        }
        if !try(storage_type.append, false)
      ]
      if storage_type.name == "os"
    ]
  )



  // List of data disks to be created for  DB nodes
  // disk_iops_read_write only apply for ultra

  data_disk_per_dbnode = (var.database_server_count > 0) ? flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          suffix                    = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
        if !try(storage_type.append, false)
      ]
      if storage_type.name != "os"
    ]
  ) : []

  append_data_disk_per_dbnode = (var.database_server_count > 0) ? flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          suffix                    = format("-%s%02d", storage_type.name, storage_type.lun_start + disk_count + var.options.resource_offset)
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
        if try(storage_type.append, false)
      ]
      if storage_type.name != "os"
    ]
  ) : []

  all_data_disk_per_dbnode = distinct(concat(local.data_disk_per_dbnode, local.append_data_disk_per_dbnode))

  anydb_disks = flatten([
    for vm_counter in range(var.database_server_count) : [
      for datadisk in local.all_data_disk_per_dbnode : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = datadisk.lun
        type                      = datadisk.type
      }
    ]
  ])

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  db_disks_ansible = distinct(flatten([for vm in range(var.database_server_count) : [
    for idx, datadisk in local.anydb_disks :
    format("{ host: '%s', LUN: %d, type: '%s' }", var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[vm], datadisk.lun, datadisk.type)
  ]]))

  enable_ultradisk = try(
    compact(
      [
        for storage in local.db_sizing : storage.disk_type == "UltraSSD_LRS" ? true : ""
      ]
    )[0],
    false
  )

  // Zones
  zones         = try(local.anydb.zones, [])
  db_zone_count = length(local.zones)

  //Ultra disk requires zonal deployment
  zonal_deployment = local.db_zone_count > 0 || local.enable_ultradisk ? true : false

  //If we deploy more than one server in zone put them in an availability set
  use_avset = var.database_server_count > 0 && try(!local.anydb.no_avset, false) ? !local.zonal_deployment || (var.database_server_count != local.db_zone_count) : false

  full_observer_names = flatten([for vm in var.naming.virtualmachine_names.OBSERVER_VMNAME :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  )

  //PPG control flag
  no_ppg = var.databases[0].no_ppg


}
