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

variable "storageaccount-bootdiagnostics" {
  description = "Details of the boot diagnostics storage account"
}

# Imports HANA database sizing information
locals {
  sizes = jsondecode(file("${path.module}/../../../hdb_sizes.json"))
}

# List of HANA DB nodes to be created
locals {
  nodes = zipmap(range(length(flatten([for database in var.databases : [ for node in database.nodes : node.name] if database.platform == "HANA"]))),flatten([for database in var.databases: [for node in database.nodes : { name = node.name, admin_nic_ip = lookup(node, "admin_nic_ip", false), db_nic_ip = lookup(node, "db_nic_ip", false), size = database.size, os = database.os, authentication = database.authentication} ] if database.platform == "HANA"]))
}
