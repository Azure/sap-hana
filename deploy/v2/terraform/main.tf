# Initalizes Azure rm provider
provider "azurerm" {
  version = "~> 1.30.1"
}

# Setup common infrastructure
module "common_infrastructure" {
  source              = "./modules/common_infrastructure"
  is_single_node_hana = "true"
  infrastructure      = var.infrastructure
}

# Create Jumpboxes and RTI box
module "jumpbox" {
  source         = "./modules/jumpbox"
  infrastructure = var.infrastructure
  jumpboxes      = var.jumpboxes
  resource-group = module.common_infrastructure.resource-group
  subnet-mgmt    = module.common_infrastructure.subnet-mgmt
  nsg-mgmt       = module.common_infrastructure.nsg-mgmt
}
