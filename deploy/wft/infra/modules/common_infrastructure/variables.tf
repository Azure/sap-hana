variable "az_region" {
}

variable "az_resource_group" {
}

variable "az_hub_vnet" {
}

variable "az_hub_address_space" {
}

variable "az_hub_subnet" {
}

variable "az_hub_subnet_prefix" {
}

variable "az_spoke_vnet" {
}

variable "az_spoke_address_space" {
}

variable "az_spoke_db_subnet" {
}

variable "az_spoke_db_subnet_prefix" {
}

variable "az_jumpbox_os" {
}

variable "az_jumpbox_private_ip_address" {
}

variable "az_vm" {
  description	= "Name of the jumpbox vm"
  default	= "jumpbox"
}

