variable "region" {
  description = "Azure region to deploy the sap setup into"
}

variable "resource_group_existing" {
  description = "Use existing resource group"
}

variable "resource_group_name" {
  description = "Name of the azure resource group to deploy the sap setup into"
}

variable "mgmt_vnet_existing" {
  description = "Use existing management vnet"
}

variable "mgmt_vnet_name" {
  description = "Name of the management vnet"
}

variable "mgmt_vnet_address_space" {
  description = "Address space of the management vnet"
}

variable "sap_vnet_existing" {
  description = "Use existing sap vnet"
}

variable "sap_vnet_name" {
  description = "Name of the sap vnet"
}

variable "sap_vnet_address_space" {
  description = "Address space of the sap vnet"
}

variable "mgmt_default_subnet_existing" {
  description = "Use existing management subnet"
}

variable "mgmt_default_subnet_name" {
  description = "Name of the management subnet"
}

variable "mgmt_default_subnet_prefix" {
  description = "Address prefix of the management subnet"
}

variable "sap_client_subnet_existing" {
  description = "Use existing sap client subnet"
}

variable "sap_client_subnet_name" {
  description = "Name of the sap client subnet"
}

variable "sap_client_subnet_prefix" {
  description = "Address prefix of the sap client subnet"
}

variable "sap_admin_subnet_existing" {
  description = "Use existing sap admin subnet"
}

variable "sap_admin_subnet_name" {
  description = "Name of the sap admin subnet"
}

variable "sap_admin_subnet_prefix" {
  description = "Address prefix of the sap admin subnet"
}

variable "sap_app_subnet_existing" {
  description = "Use existing sap application subnet"
}

variable "sap_app_subnet_name" {
  description = "Name of the sap application subnet"
}

variable "sap_app_subnet_prefix" {
  description = "Address prefix of the sap application subnet"
}

variable "mgmt_default_nsg_existing" {
  description = "Use existing management nsg"
}

variable "mgmt_default_nsg_name" {
  description = "Name of the management nsg"
}

variable "sap_client_nsg_existing" {
  description = "Use existing sap client nsg"
}

variable "sap_client_nsg_name" {
  description = "Name of the sap client nsg"
}

variable "sap_admin_nsg_existing" {
  description = "Use existing sap admin nsg"
}

variable "sap_admin_nsg_name" {
  description = "Name of the sap admin nsg"
}

variable "sap_app_nsg_existing" {
  description = "Use existing sap application nsg"
}

variable "sap_app_nsg_name" {
  description = "Name of the sap application nsg"
}
