# Initalizes Azure rm provider
provider "azurerm" {
  version = "~> 1.34.0"
}

# Setup common infrastructure
module "common_infrastructure" {
  source              = "./modules/common_infrastructure"
  is_single_node_hana = "true"
  infrastructure      = var.infrastructure
  software            = var.software
}

# Create Jumpboxes and RTI box
module "jumpbox" {
  source           = "./modules/jumpbox"
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  databases        = var.databases
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  subnet-mgmt      = module.common_infrastructure.subnet-mgmt
  nsg-mgmt         = module.common_infrastructure.nsg-mgmt
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  output-json      = module.output_json.output-json
}

# Create HANA database nodes
module "hdb_node" {
  source           = "./modules/hdb_node"
  infrastructure   = var.infrastructure
  databases        = var.databases
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  subnet-sap-admin = module.common_infrastructure.subnet-sap-admin
  nsg-admin        = module.common_infrastructure.nsg-admin
  subnet-sap-db    = module.common_infrastructure.subnet-sap-db
  nsg-db           = module.common_infrastructure.nsg-db
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
}

# Generate output JSON file
module "output_json" {
  source                 = "./modules/output_json"
  infrastructure         = var.infrastructure
  jumpboxes              = var.jumpboxes
  databases              = var.databases
  software               = var.software
  storage-sapbits        = module.common_infrastructure.storage-sapbits
  nics-windows-jumpboxes = module.jumpbox.nics-windows-jumpboxes
  nics-linux-jumpboxes   = module.jumpbox.nics-linux-jumpboxes
  nics-dbnodes-admin     = module.hdb_node.nics-dbnodes-admin
  nics-dbnodes-db        = module.hdb_node.nics-dbnodes-db
}
