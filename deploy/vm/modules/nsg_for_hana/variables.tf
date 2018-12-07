variable "az_region" {}

variable "nsg_name" {
  description = "The name of the NSG to be created."
}

variable "allow_ips" {
  description = "The ip addresses that will be allowed by the nsg"
  type        = "list"
}

variable "install_xsa" {
  description = "Flag that determines whether to install XSA on the host"
  default     = false
}

variable "use_existing_nsg" {
  description = "Lets you disable creation of the NSG if you would like to use your own"
  default     = false
}

variable "resource_group_name" {
  description = "Name of the Azure resource group that this NSG belongs to"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

locals {
  all_ips      = "\\\"*\\\""
  empty_list   = []
  empty_string = ""
}
