variable "az_region" {}

variable "resource_group_name" {
  description = "Name of the Azure resource group that this NSG belongs to"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "sap_sid" {
  default = "PV1"
}

variable "useHana2" {
  description = "If this is set to true, then, ports specifically for HANA 2.0 will be opened."
  default     = false
}
