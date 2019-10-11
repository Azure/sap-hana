variable "databases" {
  description = "Details of the HANA database nodes"
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

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

# List of HANA DB nodes to be created
locals {
  dbnodes = zipmap(range(length(flatten([for database in var.databases : [for dbnode in database.dbnodes : dbnode.name]]))), flatten([for database in var.databases : [for dbnode in database.dbnodes : { platform = database.platform, name = dbnode.name, admin_nic_ip = lookup(dbnode, "admin_nic_ip", false), db_nic_ip = lookup(dbnode, "db_nic_ip", false), size = database.size, os = database.os, authentication = database.authentication }]]))
}
