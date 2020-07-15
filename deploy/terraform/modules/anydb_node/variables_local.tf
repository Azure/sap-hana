variable "resource-group" {
  description = "Details of the resource group"
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

#TODO move to central
variable "region_mapping" {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"
  # 28 Regions 
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

  # Imports database sizing information
  sizes = jsondecode(file("${path.root}/../anydb_sizes.json"))

  # PPG Information
  ppgId = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null

  # Filter the list of databases to only AnyDB platform entries
  # Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in var.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  # if(upper(database.platform) in )
  # Enable deployment based on length of local.anydb-databases
  enable_deployment = (length(local.anydb-databases) > 0) ? true : false

  anydb          = try(local.anydb-databases[0], {})
  anydb_platform = try(local.anydb.platform, "NONE")
  anydb_version  = try(local.anydb.db_version, "")
  #TODO Add the rest of the naming convention once implemented
  anydb_nameprefix = replace(try(var.resource-group[0].name, upper(join("-", ["Test", var.region_mapping[var.resource-group[0].location], "code", local.anydb_sid]))), "-rg", "")

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
  anydb_sku    = try(lookup(local.sizes, local.anydb_size).compute.vmsize, "Standard_E4s_v3")
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

  dbnodes = flatten([
    [
      for database in local.anydb-databases : [
        for idx, dbnode in database.dbnodes : {
          platform       = local.anydb_platform,
          name           = "${local.anydb_nameprefix}-${upper(local.anydb_ostype) == "WINDOWS" ? format("%sxdb%02dw", lower(local.anydb_sid), 0) : format("%sxdb%02dl", lower(local.anydb_sid), 0)}",
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[0],
          size           = local.anydb_sku
          os             = local.anydb_ostype,
          authentication = local.authentication
          sid            = local.anydb_sid
        }
      ]
    ],
    [
      for database in local.anydb-databases : [
        for idx, dbnode in database.dbnodes : {
          platform       = local.anydb_platform,
          name           = "${local.anydb_nameprefix}-${upper(local.anydb_ostype) == "WINDOWS" ? format("%sxdb%02dw", lower(local.anydb_sid), 1) : format("%sxdb%02dl", lower(local.anydb_sid), 1)}",
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[1],
          size           = local.anydb_sku,
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
    "ORACLE" = [
      "1521"
    ]
    "DB2" = [
      "62500"
    ]
    "SQLServer" = [
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

  anydb_disks = flatten([
    for vm_counter, dbnode in local.dbnodes : [
      for storage_type in lookup(local.sizes, local.anydb_size).storage : [
        for disk_count in range(storage_type.count) : {
          vm_index                  = vm_counter
          name                      = format("%s-%s%02d", dbnode.name, storage_type.name, (disk_count))
          storage_account_type      = storage_type.disk_type
          disk_size_gb              = storage_type.size_gb
          caching                   = storage_type.caching
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ]])
}
