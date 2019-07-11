variable "az_windows_jumpbox" {
  description	= "Details of the windows jumpbox"
}

variable "az_linux_jumpbox" {
  description	= "Details of the linux jumpbox"
}

variable "az_region" {
  description	= "Azure region to deploy the jumpboxes"
}

variable "az_resource_group" {
  description	= "Resource group to deploy the jumpboxes"
}

variable "az_mgmt_subnet" {
  description	= "Subnet to deploy the jumpboxes"
}

 variable "az_bootdiag_sa" {
  description	= "Boot diagnostics storage account for the jumpboxes"
}
