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

variable "skus" {
  type = map
  default = {
    "200"   = "Standard_E4s_v3"
    "500"   = "Standard_E8s_v3"
    "1024"  = "Standard_E16s_v3"
    "2048"  = "Standard_E32s_v3"
    "5120"  = "Standard_M64ls"
    "10240" = "Standard_M64s"
    "15360" = "Standard_M64s"
    "20480" = "Standard_M64s"
  }
}


#####################################################
#
# The schema for the value part of the map is
# Number of disks
# Size of the disks
# name suffix of the disks
# SKU of the disk
# Caching setting of the disk
# WriteAccelerator setting of the disk
#
#####################################################
variable "datadisks" {
  type = map
  default = {
    "200"   = "1;255;-data;Premium_LRS;ReadWrite;false"
    "500"   = "1;511;-data;Premium_LRS;ReadWrite;false"
    "1024"  = "2;511;-data;Premium_LRS;ReadWrite;false"
    "2048"  = "2;1023;-data;Premium_LRS;ReadWrite;false"
    "5120"  = "5;1023;-data;Premium_LRS;ReadWrite;false"
    "10240" = "5;2047;-data;Premium_LRS;ReadWrite;false"
    "15360" = "4;4095;-data;Premium_LRS;ReadWrite;false"
    "20480" = "4;4095;-data;Premium_LRS;ReadWrite;false"
  }
}

variable "logdisks" {
  type = map
  default = {
    "200"   = "1;127;-log;Premium_LRS;ReadWrite;false"
    "500"   = "1;255;-log;Premium_LRS;ReadWrite;false"
    "1024"  = "2;255;-log;Premium_LRS;ReadWrite;false"
    "2048"  = "2;511;-log;Premium_LRS;ReadWrite;false"
    "5120"  = "2;511;-log;Premium_LRS;None;true"
    "10240" = "2;511;-log;Premium_LRS;None;true"
    "15360" = "2;511;-log;Premium_LRS;None;true"
    "20480" = "2;511;-log;Premium_LRS;None;true"

  }
}


locals {
  # Filter the list of databases to only HANA platform entries
  any-databases = [
    for database in var.databases : database
    if database.platform != "HANA"
  ]

  # Enable deployment based on length of local.hana-databases
  enable_deployment = (length(local.any-databases) > 0) ? true : false

  dbplatform = var.databases[0].platform

  size     = (length(local.any-databases) > 0) ? local.any-databases[0].size : 1024
  prefix   = (length(local.any-databases) > 0) ? local.any-databases[0].instance.sid : "XXX"
  vm_count = (length(local.any-databases) > 0) ? ((local.any-databases[0].high_availability == true) ? 2 : 1) : 0

  dbnodes = flatten([
    [
      for database in local.any-databases : [
        for dbnode in database.dbnodes : {
          platform       = database.platform,
          name           = format("%s-%s%02d", local.prefix, var.role, 1),
          admin_nic_ip   = lookup(dbnode, "admin_nic_ips", [false, false])[0],
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
          admin_nic_ip   = lookup(dbnode, "admin_nic_ips", [false, false])[1],
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
}

