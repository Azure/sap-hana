variable "resource-group" {
  description = "Details of the resource group"
}

variable "vnet-sap" {
  description = "Details of the SAP VNet"
}

variable "role" {
  type    = string
  default = "db"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

locals {

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

  # PPG Information
  ppgId = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null

  # Filter the list of databases to only AnyDB platform entries
  # Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in var.databases : database
    if(upper(try(database.platform), "NONE") == ("ORACLE" || "DB2" || "SQLSERVER" || "ASE"))
  ]

  # if(upper(database.platform) in ["ORACLE", "DB2", "SQLSERVER", "ASE"])
  # Enable deployment based on length of local.anydb-databases
  enable_deployment = (length(local.anydb-databases) > 0) ? true : false

  anydb          = try(local.anydb-databases[0], {})
  anydb_platform = try(local.anydb.platform, "NONE")
  anydb_version  = try(local.anydb.db_version, "")

  # OS image for all Application Tier VMs
  # If custom image is used, we do not overwrite os reference with default value
  anydb_custom_image = try(local.anydb.os.source_image_id, "") != "" ? true : false

  anydb_os = {
    "source_image_id" = local.anydb_custom_image ? local.anydb.os.source_image_id : ""
    "publisher"       = try(local.anydb.os.publisher, local.anydb_custom_image ? "" : "")
    "offer"           = try(local.anydb.os.offer, local.anydb_custom_image ? "" : "")
    "sku"             = try(local.anydb.os.sku, local.anydb_custom_image ? "" : "")
    "version"         = try(local.anydb.os.version, local.anydb_custom_image ? "" : "latest")
  }

  anydb_ostype = try(local.anydb.os.os_type, "Linux")
  anydb_size   = try(local.anydb.size, "500")
  anydb_fs     = try(local.anydb.filesystem, "xfs")
  anydb_ha     = try(local.anydb.high_availability, "false")
  anydb_sid    = (length(local.anydb-databases) > 0) ? try(local.anydb.instance.sid, "OR1") : "OR1"
  loadbalancer = try(local.anydb.loadbalancer, {})

  authentication = try(var.application.authentication,
    {
      "type"     = upper(local.anydb_ostype) == "LINUX" ? "key" : "password"
      "username" = "azureadm"
      "password" = "Sap@hana2019!"
  })

  # Update database information with defaults
  anydb_database = merge(local.anydb,
    { platform = local.anydb_platform },
    { db_version = local.anydb_version },
    { size = local.anydb_size },
    { os = local.anydb_ostype },
    { filesystem = local.anydb_fs },
    { high_availability = local.anydb_ha },
    { authentication = local.authentication }
  )

  # Imports database sizing information
  sizes = jsondecode(file("${path.root}/../anydb_sizes.json"))

  dbnodes = flatten([
    [
      for database in local.anydb-databases : [
        for dbnode in database.dbnodes : {
          platform       = local.anydb_platform,
          name           = format("%s-db%02d", local.sid, 0),
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[0],
          size           = local.anydb_size,
          os             = local.anydb_ostype,
          authentication = local.authentication
          sid            = local.anydb_sid
        }
      ]
    ],
    [
      for database in local.anydb-databases : [
        for dbnode in database.dbnodes : {
          platform       = local.anydb_platform,
          name           = format("%s-db%02d", local.sid, 1),
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[1],
          size           = local.anydb_size,
          os             = local.anydb_ostype,
          authentication = local.authentication
          sid            = local.anydb_sid
        }
      ]
      if database.high_availability
    ]
  ])

  # Ports used for specific DB Versions
  lb_ports = {
    "ASE" = [
      "1433"
    ]
    "Oracle" = [
      "1521"
    ]

    "DB2" = [
      "62500"
    ]

    "SQLServer" = [
      "59999"
    ]
  }

  loadbalancer_ports = flatten([
    for port in local.lb_ports[local.anydb_platform] : {
      port = tonumber(port)
    }
  ])

  anydb_disks = flatten([
    for vm_counter in range(length(local.dbnodes)) : [
      for storage_type in lookup(local.sizes, local.size).storage : [
        for disk_count in range(storage_type.count) : {
          vm_index                  = vm_counter
          name                      = format("%s%02d-%s-%s%02d", var.role, vm_counter, local.sid, storage_type.name, (disk_count))
          storage_account_type      = storage_type.disk_type
          disk_size_gb              = storage_type.size_gb
          caching                   = storage_type.caching
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ]])
}
