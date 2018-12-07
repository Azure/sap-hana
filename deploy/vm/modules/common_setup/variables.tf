variable "allow_ips" {
  description = "The ip addresses that will be allowed by the nsg"
  type        = "list"
}

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

variable "install_xsa" {
  description = "Flag that determines whether to install XSA on the host"
  default     = false
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

locals {
  empty_string = ""
  new_nsg_name = "${var.sap_sid}-nsg"
}
