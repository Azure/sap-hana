variable "sap_sid" {
  default = "PV1"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group that this NSG belongs to"
}

variable "az_region" {}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}
