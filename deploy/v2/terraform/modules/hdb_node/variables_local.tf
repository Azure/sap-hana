variable "resource-group" {
  description = "Details of the resource group"
}

variable "subnet-sap-admin" {
  description = "Details of the SAP admin subnet"
}

variable "subnet-sap-db" {
  description = "Details of the SAP DB subnet"
}

variable "nsg-admin" {
  description = "Details of the SAP admin subnet NSG"
}

variable "nsg-db" {
  description = "Details of the SAP DB subnet NSG"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

# Imports HANA database sizing information
locals {
  sizes = jsondecode(file("${path.root}/../hdb_sizes.json"))
}

locals {
  # Numerically indexed Hash of HANA DB nodes to be created
  dbnodes = zipmap(
    range(
      length(
        flatten([
          for database in var.databases : [
            for dbnode in database.dbnodes : dbnode.name
          ]
          if database.platform == "HANA"
        ])
      )
    ),
    flatten([
      for database in var.databases : [
        for dbnode in database.dbnodes : {
          platform       = database.platform,
          name           = dbnode.name,
          admin_nic_ip   = lookup(dbnode, "admin_nic_ip", false),
          db_nic_ip      = lookup(dbnode, "db_nic_ip", false),
          size           = database.size,
          os             = database.os,
          authentication = database.authentication
          sid            = database.instance.sid
        }
      ]
      if database.platform == "HANA"
    ])
  )

  # Ports used for specific HANA Versions
  lb_ports = {
    "1" = [
      "30015",
      "30017",
    ]

    "2" = [
      "30013",
      "30015",
      "30040",
      "30041",
      "30042",
    ]
  }

  # Hash of Load Balancers to create for HANA instances
  loadbalancers = zipmap(
    range(
      length([
        for database in var.databases : database.instance.sid
        if database.platform == "HANA"
      ])
    ),
    [
      for database in var.databases : {
        sid             = database.instance.sid
        instance_number = database.instance.instance_number
        ports           = [
          for port in local.lb_ports[split(".", database.db_version)[0]] : tonumber(port) + (tonumber(database.instance.instance_number) * 100)
        ]
        lb_fe_ip        = lookup(database, "lb_fe_ip", false),
      }
      if database.platform == "HANA"
    ]
  )
}

# List of data disks to be created for HANA DB nodes
locals {
  data-disk-per-dbnode = flatten([
    for storage_type in lookup(local.sizes, local.dbnodes[0].size).storage : [
      for disk_count in range(storage_type.count) : {
        name                      = join("-", [storage_type.name, disk_count])
        storage_account_type      = storage_type.disk_type,
        disk_size_gb              = storage_type.size_gb,
        caching                   = storage_type.caching,
        write_accelerator_enabled = storage_type.write_accelerator
      }
    ]
    if storage_type.name != "os"
  ])

  data-disk-list = flatten([
    for database in var.databases : [
      for dbnode in database.dbnodes : [
        for datadisk in local.data-disk-per-dbnode : {
          name                      = join("-", [dbnode.name, datadisk.name])
          caching                   = datadisk.caching
          storage_account_type      = datadisk.storage_account_type
          disk_size_gb              = datadisk.disk_size_gb
          write_accelerator_enabled = datadisk.write_accelerator_enabled
        }
      ]
    ]
    if database.platform == "HANA"
    ]
  )
}
