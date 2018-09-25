variable "az_region" {}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "bastion_username" {
  description = "The username for the bastion host"
}

variable "pw_bastion" {
  description = "The password for the bastion host"
}

variable "isLinux" {
  default = false
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}

variable "sap_sid" {
  description = "SAP Instance number"
}

variable "subnet_id" {
  default     = "bastion_subnet"
  description = "The id of the subnet the bastion host will be in.  This should be different than the HANA vms."
}

locals {
  machine_name = "${lower(var.sap_sid)}-bastion"
}
