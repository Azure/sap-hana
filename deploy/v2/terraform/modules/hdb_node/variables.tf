variable "databases" {
  description = "Details of the HANA database nodes"
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "resource-group" {
  description = "Details of the resource group"
}

variable "subnet-admin" {
  description = "Details of the SAP admin subnet"
}

variable "subnet-db" {
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
  sizes = jsondecode(file("../../../hdb_sizes.json"))
}
