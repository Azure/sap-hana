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

variable "random-id" {
  description = "Random hex string"
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

locals {
  region         = try(var.infrastructure.region, "")
  landscape      = lower(try(var.infrastructure.landscape, ""))
  sid            = upper(try(var.application.sid, local.anydb_sid))
  codename       = lower(try(var.infrastructure.codename, ""))
  location_short = lower(try(var.region_mapping[local.region], "unkn"))
  // Using replace "--" with "-" and "_-" with "-" in case of one of the components like codename is empty
  prefix    = try(local.var_infra.resource_group.name, upper(replace(replace(format("%s-%s-%s_%s-%s", local.landscape, local.location_short, substr(local.vnet_sap_name_prefix, 0, 7), local.codename, local.sid), "_-", "-"), "--", "-")))
  sa_prefix = lower(replace(format("%s%s%sdiag", substr(local.landscape, 0, 5), local.location_short, substr(local.codename, 0, 7)), "--", "-"))

  # SAP vnet
  var_infra       = try(var.infrastructure, {})
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_exists = try(local.var_vnet_sap.is_existing, false)
  vnet_sap_arm_id = local.vnet_sap_exists ? try(local.var_vnet_sap.arm_id, "") : ""
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, "sap")
  vnet_nr_parts   = length(split("-", local.vnet_sap_name))
  // Default naming of vnet has multiple parts. Taking the second-last part as the name 
  vnet_sap_name_prefix = try(substr(upper(local.vnet_sap_name), -5, 5), "") == "-VNET" ? split("-", local.vnet_sap_name)[(local.vnet_nr_parts -2)] : local.vnet_sap_name

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

  // Imports database sizing information
  sizes = jsondecode(file("${path.module}/../../../../../configs/anydb_sizes.json"))

  // PPG Information
  ppgId = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null

  anydb          = try(local.anydb-databases[0], {})
  anydb_platform = try(local.anydb.platform, "NONE")
  anydb_version  = try(local.anydb.db_version, "")

  // Filter the list of databases to only AnyDB platform entries
  // Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in var.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  // Enable deployment based on length of local.anydb-databases
  enable_deployment = (length(local.anydb-databases) > 0) ? true : false

  // If custom image is used, we do not overwrite os reference with default value
  anydb_custom_image = try(local.anydb.os.source_image_id, "") != "" ? true : false

  anydb_ostype = try(local.anydb.os.os_type, "Linux")
  anydb_oscode = upper(local.anydb_ostype) == "LINUX" ? "l" : "w"
  anydb_size   = try(local.anydb.size, "500")
  anydb_sku    = try(lookup(local.sizes, local.anydb_size).compute.vmsize, "Standard_E4s_v3")
  anydb_fs     = try(local.anydb.filesystem, "xfs")
  anydb_ha     = try(local.anydb.high_availability, false)
  anydb_sid    = (length(local.anydb-databases) > 0) ? try(local.anydb.instance.sid, lower(substr(local.anydb_platform, 0, 3))) : lower(substr(local.anydb_platform, 0, 3))
  loadbalancer = try(local.anydb.loadbalancer, {})

  authentication = try(local.anydb.authentication,
    {
      "type"     = upper(local.anydb_ostype) == "LINUX" ? "key" : "password"
      "username" = "azureadm"
      "password" = "Sap@hana2019!"
  })

  anydb_cred           = try(local.anydb.credentials, {})
  db_systemdb_password = try(local.anydb_cred.db_systemdb_password, "")

  // Default values in case not provided
  os_defaults = {
    ORACLE = {
      "publisher" = "Oracle",
      "offer"     = "Oracle-Linux",
      "sku"       = "77",
      "version"   = "latest"
    }
    DB2 = {
      "publisher" = "suse",
      "offer"     = "sles-sap-12-sp5",
      "sku"       = "gen1"
      "version"   = "latest"
    }
    ASE = {
      "publisher" = "suse",
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

  // Update database information with defaults
  anydb_database = merge(local.anydb,
    { platform = local.anydb_platform },
    { db_version = local.anydb_version },
    { size = local.anydb_size },
    { os = merge({ os_type = local.anydb_ostype }, local.anydb_os) },
    { filesystem = local.anydb_fs },
    { high_availability = local.anydb_ha },
    { authentication = local.authentication },
    { credentials = {
      db_systemdb_password = local.db_systemdb_password
      }
    },
    { dbnodes = local.dbnodes },
    { loadbalancer = local.loadbalancer }
  )

  customer_provided_names = try(local.anydb.dbnodes[0].name, "") == "" ? false : true

  dbnodes = flatten([[for idx, dbnode in try(local.anydb.dbnodes, [{}]) : {
    name      = try("${dbnode.name}-0", format("%sd%s%03d%s%d%s", local.sid, local.anydb_sid, idx, local.anydb_oscode, idx, substr(var.random-id.hex, 0, 3))),
    role      = try(dbnode.role, "worker"),
    db_nic_ip = lookup(dbnode, "db_nic_ips", [false, false])[0]
    }
    ],
    [for idx, dbnode in try(local.anydb.dbnodes, [{}]) : {
      name      = try("${dbnode.name}-1", format("%sd%s%03d%s%d%s", local.sid, local.anydb_sid, idx + try(length(local.anydb.dbnodes), 1), local.anydb_oscode, idx + try(length(local.anydb.dbnodes), 1), substr(var.random-id.hex, 0, 3)))
      role      = try(dbnode.role, "worker"),
      db_nic_ip = lookup(dbnode, "db_nic_ips", [false, false])[1],
      } if local.anydb_ha
    ]
    ]
  )

  anydb_vms = [
    for idx, dbnode in local.dbnodes : {
      platform       = local.anydb_platform,
      name           = dbnode.name
      db_nic_ip      = dbnode.db_nic_ip
      size           = local.anydb_sku
      os             = local.anydb_ostype,
      authentication = local.authentication
      sid            = local.anydb_sid
    }
  ]

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
    for vm_counter, anydb_vm in local.anydb_vms : [
      for storage_type in lookup(local.sizes, local.anydb_size).storage : [
        for disk_count in range(storage_type.count) : {
          vm_index                  = vm_counter
          name                      = local.customer_provided_names ? format("%s-%s%02d", anydb_vm.name, storage_type.name, (disk_count)) : format("%s_%s-%s%02d", local.prefix, anydb_vm.name, storage_type.name, (disk_count))
          storage_account_type      = storage_type.disk_type
          disk_size_gb              = storage_type.size_gb
          caching                   = storage_type.caching
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ]])
}
