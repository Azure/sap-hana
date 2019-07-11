variable "az_credentials" {
  description = "The login credentials of the azure subscription"
}

variable "az_region" {
  description = "Azure region to deploy the setup into. e.g. <eastus>"
}

variable "az_resource_group_name" {
  description = "Name of azure resource group to deploy the setup into.  i.e. <myResourceGroup>"
}

variable "az_vnet" {
  description = "Azure vnet and subnet details"
}

variable "az_windows_jumpbox" {
  description = "Windows jumpbox configuration details"
}

variable "az_linux_jumpbox" {
  description = "Linux jumpbox configuration details"
}

variable "existing_resources" {
  description = "Ids of exsting azure resources"
}
