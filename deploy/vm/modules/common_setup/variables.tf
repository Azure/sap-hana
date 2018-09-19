variable "az_region" {}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "sap_sid" {
  default = "PV1"
}

variable "useHana2" {
  description = "A boolean that will choose between HANA 1.0 and 2.0"
  default     = false
}
