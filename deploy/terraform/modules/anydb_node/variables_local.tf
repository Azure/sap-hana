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

  # Filter the list of databases to only HANA platform entries
  any-databases = [
    for database in var.databases : database
    if(database.platform != "HANA" && database.platform != "NONE")
  ]

  anydb          = try(local.any-databases[0], {})
  anydb_platform = try(local.anydb.platform, "NONE")
  anydb_version  = try(local.anydb.db_version, "7.5.1")

  anydb_customimage = { "source_image_id" : try(local.anydb.os.source_image_id, "") }
  anydb_marketplaceimage = try(local.anydb.os,
    {
      "os_type" : "Linux"
      "publisher" : "Oracle",
      "offer" : "Oracle-Linux",
      "sku" : "7.5",
  "version" : "latest" })

  anydb_image = try(var.application.os.source_image_id, null) == null ? local.anydb_marketplaceimage : local.anydb_customimage


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
  vm_count = (length(local.any-databases) > 0) ? (try(local.anydb.high_availability, false) ? 2 : 1) : 0
  sku      = try(lookup(local.sizes, local.size).compute.vm_size, "Standard_E4s_v3")

  #As we don't know if the server is a Windows or Linux Server we merge these
  vms = flatten([[for vm in azurerm_linux_virtual_machine.dbserver : {
    name = vm.name
    id   = vm.id
    }], [for vm in azurerm_windows_virtual_machine.dbserver : {
    name = vm.name
    id   = vm.id
    }]
    #   ,
    #   [for vm in azurerm_linux_virtual_machine.dbserver_customimage : {
    #     name = vm.name
    #     id   = vm.id
    #     }], [for vm in azurerm_windows_virtual_machine.dbserver_customimage : {
    #     name = vm.name
    #     id   = vm.id
    # }]
  ])

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

  data-disk-per-dbnode = flatten(
    [
      for storage_type in lookup(local.sizes, local.size).storage : [
        for disk_count in range(storage_type.count) : {
          name                      = format("%s%02d", storage_type.name, (disk_count + 1))
          storage_account_type      = storage_type.disk_type
          disk_size_gb              = storage_type.size_gb
          caching                   = storage_type.caching
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
  ])

  #This is the combined list for all disks for all VMs
  allDataDisks = flatten([for vm in local.vms : [for luncount in range(length(local.data-disk-per-dbnode)) : {
    name                      = format("%s-%s", vm.name, local.data-disk-per-dbnode[luncount].name)
    caching                   = local.data-disk-per-dbnode[luncount].caching
    storage_account_type      = local.data-disk-per-dbnode[luncount].storage_account_type
    disk_size_gb              = local.data-disk-per-dbnode[luncount].disk_size_gb
    write_accelerator_enabled = local.data-disk-per-dbnode[luncount].write_accelerator_enabled
    virtual_machine_id        = vm.id
    lun                       = luncount
  }]])



}
