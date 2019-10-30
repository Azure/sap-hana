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
  options             = var.options
}

# Create Jumpboxes and RTI box
module "jumpbox" {
  source            = "./modules/jumpbox"
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  databases         = var.databases
  sshkey            = var.sshkey
  resource-group    = module.common_infrastructure.resource-group
  subnet-mgmt       = module.common_infrastructure.subnet-mgmt
  nsg-mgmt          = module.common_infrastructure.nsg-mgmt
  storage-bootdiag  = module.common_infrastructure.storage-bootdiag
  output-json       = module.output_files.output-json
  ansible-inventory = module.output_files.ansible-inventory
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

# Generate output files
module "output_files" {
  source                       = "./modules/output_files"
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  databases                    = var.databases
  software                     = var.software
  storage-sapbits              = module.common_infrastructure.storage-sapbits
  nics-jumpboxes-windows       = module.jumpbox.nics-jumpboxes-windows
  nics-jumpboxes-linux         = module.jumpbox.nics-jumpboxes-linux
  public-ips-jumpboxes-windows = module.jumpbox.public-ips-jumpboxes-windows
  public-ips-jumpboxes-linux   = module.jumpbox.public-ips-jumpboxes-linux
  nics-dbnodes-admin           = module.hdb_node.nics-dbnodes-admin
  nics-dbnodes-db              = module.hdb_node.nics-dbnodes-db
}
