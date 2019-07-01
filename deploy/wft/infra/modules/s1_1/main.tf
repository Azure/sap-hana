# Initalizes Azure modules and authenticates to subscription
provider "azurerm" {
  version = "~> 1.30.1"
  subscription_id	= var.subscription_id
  client_id		= var.client_id
  client_secret		= var.client_secret
  tenant_id		= var.tenant_id
}

# Creates common infrastructure setup
  module "a_common_infrastructure" {
  source			= "../common_infrastructure"
  az_region			= var.az_region
  az_resource_group		= var.az_resource_group
  az_hub_vnet			= var.az_hub_vnet
  az_hub_address_space		= var.az_hub_address_space
  az_hub_subnet			= var.az_hub_subnet
  az_hub_subnet_prefix		= var.az_hub_subnet_prefix
  az_spoke_vnet			= var.az_spoke_vnet
  az_spoke_address_space	= var.az_spoke_address_space
  az_spoke_db_subnet		= var.az_spoke_db_subnet
  az_spoke_db_subnet_prefix	= var.az_spoke_db_subnet_prefix
  az_jumpbox_os			= var.az_jumpbox_os
  az_jumpbox_private_ip_address	= var.az_jumpbox_private_ip_address
}

 












