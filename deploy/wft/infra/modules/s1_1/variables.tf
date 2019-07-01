variable "subscription_id"{
  description	= "The Subscription ID of the Azure susbcription"
}

variable "client_id"{
  description	= "The Client ID of the Azure Service Principal"
}

variable "client_secret"{
  description	= "The Client secret of the Azure Service Principal"
}

variable "tenant_id"{
  description	= "The Tenant ID of the Azure susbcription"
}

variable "az_region" {
  description	= "Which Azure region to deploy the HANA setup into. e.g. <eastus>"
  default	= "eastus"
}

variable "az_resource_group" {
  description	= "Which Azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
  default	= "demo-rg"
}

variable "az_hub_vnet" {
  description	= "Name of the Hub VNET to deploy the Jumpbox into"
  default	= "hub-vnet"
}

variable "az_hub_address_space" {
  description	= "Address space of the Hub VNET"
  default	= "10.0.0.0/16"
}

variable "az_hub_subnet" {
  description	= "Name of the Hub Subnet to deploy the Jumpbox into"
  default	= "hub-subnet"
}

variable "az_hub_subnet_prefix" {
  description	= "Address Prefix of the Hub Subnet"
  default	= "10.0.1.0/24"
}

variable "az_spoke_vnet" {
  description	= "Name of the Spoke VNET"
  default	= "spoke-vnet"
}

variable "az_spoke_address_space" {
  description	= "Address space of the spoke VNET"
  default	= "10.1.0.0/16"
}

variable "az_spoke_db_subnet" {
  description	= "Name of the spoke DB Subnet to deploy the DB servers"
  default	= "spoke-db-subnet"
}

variable "az_spoke_db_subnet_prefix" {
  description	= "Address Prefix of the Spoke DB Subnet"
  default	= "10.1.1.0/24"
}

variable "az_jumpbox_os" {
  description	= "Operating system of the Jumpbox"
  default	= "windows"
}

variable "az_jumpbox_private_ip_address" {
  description	= "Private ip address of the Jumpbox"
  default	= "10.0.1.5"
}
