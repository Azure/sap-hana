variable "az_region" {
  description	= "Which Azure region to deploy the HANA setup into. e.g. <eastus>"
}

variable "az_resource_group" {
  description	= "Which Azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "az_hub_vnet" {
  description	= "Name of the Hub VNET to deploy the Jumpbox into"
}

variable "az_hub_address_space" {
  description	= "Address space of the Hub VNET"
}

variable "az_hub_subnet" {
  description	= "Name of the Hub Subnet to deploy the Jumpbox"
}

variable "az_hub_subnet_prefix" {
  description	= "Address Prefix of the Hub Subnet"
}

variable "az_spoke_vnet" {
  description	= "Name of the spoke vnet"
}

variable "az_spoke_address_space" {
  description	= "Address space of the spoke vnet"
}

variable "az_spoke_db_client_subnet" {
  description	= "Name of the spoke DB client Subnet"
}

variable "az_spoke_db_admin_subnet" {
  description	= "Name of the spoke DB admin Subnet"
}

variable "az_spoke_db_client_subnet_prefix" {
  description	= "Address Prefix of the Spoke DB Client Subnet"
}

variable "az_spoke_db_admin_subnet_prefix" {
  description	= "Address Prefix of the Spoke DB Admin Subnet"
}

variable "az_jumpbox_os" {
  description	= "Operating system of the Jumpbox"
}

variable "az_jumpbox_private_ip_address" {
  description	= "Private ip address of the Jumpbox"
}

variable "az_vm" {
  description	= "Name of the jumpbox vm"
  default	= "jumpbox"
}

