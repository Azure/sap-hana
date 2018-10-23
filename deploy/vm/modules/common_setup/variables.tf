variable "az_region" {}

variable "az_resource_group" {
  description = "Which Azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "use_existing_nsg" {
  default     = ""
  description = "If this variable is provided, then use that nsg, otherwise a new one will be created for you"
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
}
