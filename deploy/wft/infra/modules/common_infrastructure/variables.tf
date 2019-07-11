variable "az_region" {
  description	= "Which azure region to deploy the hana setup into. e.g. <eastus>"
}

variable "az_resource_group_id" {
  description	= "Id of the existing azure resource group to deploy the hana setup into.  i.e. <myResourceGroup>"
}

variable "az_mgmt_vnet_id" {
  description	= "Id of the existing management vnet"
}

variable "az_mgmt_subnet_id" {
  description	= "Id of the existing management subnet"
}

variable "az_hana_vnet_id" {
  description	= "Id of the existing hana vnet"
}

variable "az_hana_client_subnet_id" {
  description	= "Id of the existing hana client subnet"
}

variable "az_hana_admin_subnet_id" {
  description	= "Id of the existing hana admin subnet"
}

variable "az_resource_group_name" {
  description	= "Name of azure resource group to deploy the hana setup into.  i.e. <myResourceGroup>"
}

variable "az_mgmt_vnet_name" {
  description	= "Name of the management vnet"
}

variable "az_mgmt_vnet_address_space" {
  description	= "Address space of the management vnet"
}

variable "az_mgmt_subnet_name" {
  description	= "Name of the management subnet"
}

variable "az_mgmt_subnet_prefix" {
  description	= "Address prefix of the management subnet"
}

variable "az_hana_vnet_name" {
  description	= "Name of the hana vnet"
}

variable "az_hana_vnet_address_space" {
  description	= "Address space of the hana vnet"
}

variable "az_hana_client_subnet_name" {
  description	= "Name of the hana client subnet"
}

variable "az_hana_admin_subnet_name" {
  description	= "Name of the hana admin subnet"
}

variable "az_hana_client_subnet_prefix" {
  description	= "Address prefix of the hana client subnet"
}

variable "az_hana_admin_subnet_prefix" {
  description	= "Address prefix of the hana admin subnet"
}
