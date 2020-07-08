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

  # Imports database sizing information
  sizes = jsondecode(file("${path.root}/../anydb_sizes.json"))

  # Filter the list of databases to only AnyDB platform entries
  any-databases = [
    for database in var.databases : database
    if(database.platform != "HANA" && database.platform != "NONE")
  ]

  anydb          = try(local.any-databases[0], {})
  anydb_platform = try(local.anydb.platform, "NONE")
  anydb_version  = try(local.anydb.db_version, "7.5.1")

  # OS image for all Application Tier VMs
  # If custom image is used, we do not overwrite os reference with default value
  anydb_custom_image = try(local.anydb.os.source_image_id, "") != "" ? true : false

  anydb_os = {
    "source_image_id" = local.anydb_custom_image ? local.anydb.os.source_image_id : ""
    "publisher"       = try(local.anydb.os.publisher, local.anydb_custom_image ? "" : "suse")
    "offer"           = try(local.anydb.os.offer, local.anydb_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.anydb.os.sku, local.anydb_custom_image ? "" : "gen1")
    "version"         = try(local.anydb.os.version, local.anydb_custom_image ? "" : "latest")
  }

  anydb_ostype = try(local.anydb.os.type, "Linux")
  anydb_size   = try(local.anydb.size, "500")
  anydb_fs     = try(local.anydb.filesystem, "xfs")
  anydb_ha     = try(local.anydb.high_availability, "false")
  anydb_auth = try(local.anydb.authentication,
    {
      "type"     = "key"
      "username" = "azureadm"
  })
  
  # Enable deployment based on length of local.any-databases
  enable_deployment = (length(local.any-databases) > 0) ? true : false

  size     = try(local.anydb.size, "500")
  prefix   = (length(local.any-databases) > 0) ? try(local.anydb.instance.sid, "ANY") : "ANY"
  vm_count = (length(local.any-databases) > 0) ? (try(local.anydb.high_availability, true) ? 2 : 1) : 0
  sku      = try(lookup(local.sizes, local.size).compute.vm_size, "Standard_E4s_v3")

  dbnodes = flatten([
    [
      for database in local.any-databases : [
        for dbnode in database.dbnodes : {
          platform       = database.platform,
          name           = format("%s-%s%02d", local.prefix, var.role, 1),
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[0],
          size           = database.size,
          os             = database.os,
          authentication = database.authentication
          sid            = database.instance.sid
        }
      ]
    ],
    [
      for database in local.any-databases : [
        for dbnode in database.dbnodes : {
          platform       = database.platform,
          name           = format("%s-%s%02d", local.prefix, var.role, 2),
          db_nic_ip      = lookup(dbnode, "db_nic_ips", [false, false])[1],
          size           = database.size,
          os             = database.os,
          authentication = database.authentication
          sid            = database.instance.sid
        }
      ]
      if database.high_availability
    ]
  ])

  # Ports used for specific DB Versions
  lb_ports = {
    "AnyDB" = [
      "1433"
    ]
    "Oracle" = [
      "80",
      "1433"
    ]

    "DB2" = [
      "80",
      "1433"
    ]

    "NONE" = [
    ]
  }

  # Hash of Load Balancers to create for HANA instances
  loadbalancers = zipmap(
    range(
      length([
        for database in local.any-databases : database.instance.sid
      ])
    ),
    [
      for database in local.any-databases : {
        sid = database.instance.sid
        ports = [
          for port in local.lb_ports[database.platform] : tonumber(port)
        ]
        frontend_ip = lookup(lookup(database, "loadbalancer", {}), "frontend_ip", false),
      }
    ]
  )

  # List of ports for load balancer
  loadbalancers-ports = length(local.loadbalancers) > 0 ? local.loadbalancers[0].ports : []

  # Update database information with defaults
  anydb_database = merge(local.anydb,
    { platform = local.anydb_platform },
    { db_version = local.anydb_version },
    { os = local.anydb_ostype },
    { size = local.anydb_size },
    { filesystem = local.anydb_fs },
    { high_availability = local.anydb_ha },
  { authentication = local.anydb_auth })

  anydb_disks = flatten([
    for vm_counter in range(local.vm_count) : [
      for storage_type in lookup(local.sizes, local.size).storage : [
        for disk_count in range(storage_type.count) : {
          vm_index                  = vm_counter
          name                      = format("%s%02d-%s-%s%02d", var.role, (vm_counter + 1), local.prefix,storage_type.name, (disk_count + 1))
          storage_account_type      = storage_type.disk_type
          disk_size_gb              = storage_type.size_gb
          caching                   = storage_type.caching
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ]])
}
