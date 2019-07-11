# Initalizes Azure modules and authenticates to subscription
provider "azurerm" {
  version         = "~> 1.30.1"
  subscription_id = var.az_credentials.subscription_id
  client_id       = var.az_credentials.client_id
  client_secret   = var.az_credentials.client_secret
  tenant_id       = var.az_credentials.tenant_id
}

# Setup common infrastructure
module "common_infrastructure" {
  source                       = "../common_infrastructure"
  az_region                    = var.az_region
  az_resource_group_id	       = var.existing_resources.resource_group_id
  az_mgmt_vnet_id	       = var.existing_resources.mgmt_vnet_id
  az_hana_vnet_id	       = var.existing_resources.hana_vnet_id
  az_mgmt_subnet_id	       = var.existing_resources.mgmt_subnet_id
  az_hana_client_subnet_id     = var.existing_resources.hana_client_subnet_id
  az_hana_admin_subnet_id      = var.existing_resources.hana_admin_subnet_id
  az_resource_group_name       = var.az_resource_group_name
  az_mgmt_vnet_name            = var.az_vnet.mgmt_vnet_name
  az_mgmt_vnet_address_space   = var.az_vnet.mgmt_vnet_address_space
  az_mgmt_subnet_name          = var.az_vnet.mgmt_subnet_name
  az_mgmt_subnet_prefix        = var.az_vnet.mgmt_subnet_prefix
  az_hana_vnet_name            = var.az_vnet.hana_vnet_name
  az_hana_vnet_address_space   = var.az_vnet.hana_vnet_address_space
  az_hana_client_subnet_name   = var.az_vnet.hana_client_subnet_name
  az_hana_client_subnet_prefix = var.az_vnet.hana_client_subnet_prefix
  az_hana_admin_subnet_name    = var.az_vnet.hana_admin_subnet_name
  az_hana_admin_subnet_prefix  = var.az_vnet.hana_admin_subnet_prefix
}

# Creates jumpboxes
module "jumpbox" {
  source		= "../resources/jumpbox"
  az_region		= var.az_region
  az_resource_group	= module.common_infrastructure.resource_group
  az_windows_jumpbox	= var.az_windows_jumpbox
  az_linux_jumpbox	= var.az_linux_jumpbox
  az_mgmt_subnet	= module.common_infrastructure.mgmt_subnet
  az_bootdiag_sa	= module.common_infrastructure.bootdiag_sa
  
}
