# Initalizes azure modules and authenticates to subscription
provider "azurerm" {
  version = "~> 1.30.1"
}

# Setup common infrastructure
module "common_infrastructure" {
  source                       = "../common_infrastructure"
  region                       = var.infrastructure.region
  resource_group_existing      = var.infrastructure.resource_group.is_existing
  resource_group_name          = var.infrastructure.resource_group.name
  mgmt_vnet_existing           = var.infrastructure.vnets.management.is_existing
  mgmt_vnet_name               = var.infrastructure.vnets.management.name
  mgmt_vnet_address_space      = var.infrastructure.vnets.management.address_space
  sap_vnet_existing            = var.infrastructure.vnets.sap.is_existing
  sap_vnet_name                = var.infrastructure.vnets.sap.name
  sap_vnet_address_space       = var.infrastructure.vnets.sap.address_space
  mgmt_default_subnet_existing = var.infrastructure.vnets.management.default_subnet.is_existing
  mgmt_default_subnet_name     = var.infrastructure.vnets.management.default_subnet.name
  mgmt_default_subnet_prefix   = var.infrastructure.vnets.management.default_subnet.prefix
  sap_admin_subnet_existing    = var.infrastructure.vnets.sap.admin_subnet.is_existing
  sap_admin_subnet_name        = var.infrastructure.vnets.sap.admin_subnet.name
  sap_admin_subnet_prefix      = var.infrastructure.vnets.sap.admin_subnet.prefix
  sap_client_subnet_existing   = var.infrastructure.vnets.sap.client_subnet.is_existing
  sap_client_subnet_name       = var.infrastructure.vnets.sap.client_subnet.name
  sap_client_subnet_prefix     = var.infrastructure.vnets.sap.client_subnet.prefix
  sap_app_subnet_existing      = var.infrastructure.vnets.sap.app_subnet.is_existing
  sap_app_subnet_name          = var.infrastructure.vnets.sap.app_subnet.name
  sap_app_subnet_prefix        = var.infrastructure.vnets.sap.app_subnet.prefix
  mgmt_default_nsg_existing    = var.infrastructure.vnets.management.default_subnet.nsg.is_existing
  mgmt_default_nsg_name        = var.infrastructure.vnets.management.default_subnet.nsg.name
  sap_admin_nsg_existing       = var.infrastructure.vnets.sap.admin_subnet.nsg.is_existing
  sap_admin_nsg_name           = var.infrastructure.vnets.sap.admin_subnet.nsg.name
  sap_client_nsg_existing      = var.infrastructure.vnets.sap.client_subnet.nsg.is_existing
  sap_client_nsg_name          = var.infrastructure.vnets.sap.client_subnet.nsg.name
  sap_app_nsg_existing         = var.infrastructure.vnets.sap.app_subnet.nsg.is_existing
  sap_app_nsg_name             = var.infrastructure.vnets.sap.app_subnet.nsg.name
}
