variable "az_region" {}

variable "az_resource_group" {
  description = "Which Azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "existing_nsg_name" {
  description = "The name of the pre-existing nsg that you would like to use"
  default     = ""
}

variable "existing_nsg_rg" {
  description = "The name of the pre-existing resource group that you would like to use"
  default     = ""
}

variable "use_existing_nsg" {
  default     = false
  description = "When set to true, and the appropriate variables are provided, will use that nsg instead of creating a new one"
}

variable "sap_instancenum" {
  description = "The SAP instance number which is in range 00-99."
}

variable "sap_sid" {
  default = "PV1"
}

variable "useHana2" {
  description = "A boolean that will choose between HANA 1.0 and 2.0."
  default     = false
}

locals {
  empty_string = ""
  new_nsg_name = "${var.sap_sid}-nsg"
}
