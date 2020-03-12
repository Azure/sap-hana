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
