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
  source                         = "./modules/jumpbox"
  infrastructure                 = var.infrastructure
  jumpboxes                      = var.jumpboxes
  resource-group                 = module.common_infrastructure.resource-group
  subnet-mgmt                    = module.common_infrastructure.subnet-mgmt
  nsg-mgmt                       = module.common_infrastructure.nsg-mgmt
  storageaccount-bootdiagnostics = module.common_infrastructure.storageaccount-bootdiagnostics
  output-json                    = module.output_json.output-json
}

# Create HANA database nodes
module "hdb_node" {
  source                         = "./modules/hdb_node"
  infrastructure                 = var.infrastructure
  databases                      = var.databases
  resource-group                 = module.common_infrastructure.resource-group
  subnet-sap-admin               = module.common_infrastructure.subnet-sap-admin
  nsg-admin                      = module.common_infrastructure.nsg-admin
  subnet-sap-db                  = module.common_infrastructure.subnet-sap-db
  nsg-db                         = module.common_infrastructure.nsg-db
  storageaccount-bootdiagnostics = module.common_infrastructure.storageaccount-bootdiagnostics
}

# Generate output JSON file
module "output_json" {
  source           = "./modules/output_json"
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  databases        = var.databases
  nic-windows      = module.jumpbox.nic-windows
  nic-linux        = module.jumpbox.nic-linux
  nic-dbnode-admin = module.hdb_node.nic-dbnode-admin
  nic-dbnode-db    = module.hdb_node.nic-dbnode-db
}
