# Setup common infrastructure
module "common_infrastructure" {
  source              = "./modules/common_infrastructure"
  is_single_node_hana = "true"
  application         = var.application
  databases           = var.databases
  infrastructure      = var.infrastructure
  jumpboxes           = var.jumpboxes
  options             = var.options
  software            = var.software
  ssh-timeout         = var.ssh-timeout
  sshkey              = var.sshkey
}

# Create Jumpboxes and RTI box
module "jumpbox" {
  source            = "./modules/jumpbox"
  application       = var.application
  databases         = var.databases
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  options           = var.options
  software          = var.software
  ssh-timeout       = var.ssh-timeout
  sshkey            = var.sshkey
  resource-group    = module.common_infrastructure.resource-group
  subnet-mgmt       = module.common_infrastructure.subnet-mgmt
  nsg-mgmt          = module.common_infrastructure.nsg-mgmt
  storage-bootdiag  = module.common_infrastructure.storage-bootdiag
  output-json       = module.output_files.output-json
  ansible-inventory = module.output_files.ansible-inventory
  random-id         = module.common_infrastructure.random-id
}

# Create HANA database nodes
module "hdb_node" {
  source           = "./modules/hdb_node"
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = var.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
}

# Create Application Tier nodes
module "app_tier" {
  source           = "./modules/app_tier"
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = var.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
}

# Generate output files
module "output_files" {
  source                       = "./modules/output_files"
  application                  = var.application
  databases                    = var.databases
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  options                      = var.options
  software                     = var.software
  ssh-timeout                  = var.ssh-timeout
  sshkey                       = var.sshkey
  storage-sapbits              = module.common_infrastructure.storage-sapbits
  nics-iscsi                   = module.common_infrastructure.nics-iscsi
  nics-jumpboxes-windows       = module.jumpbox.nics-jumpboxes-windows
  nics-jumpboxes-linux         = module.jumpbox.nics-jumpboxes-linux
  public-ips-jumpboxes-windows = module.jumpbox.public-ips-jumpboxes-windows
  public-ips-jumpboxes-linux   = module.jumpbox.public-ips-jumpboxes-linux
  jumpboxes-linux              = module.jumpbox.jumpboxes-linux
  nics-dbnodes-admin           = module.hdb_node.nics-dbnodes-admin
  nics-dbnodes-db              = module.hdb_node.nics-dbnodes-db
  loadbalancers                = module.hdb_node.loadbalancers
  hdb-sid                      = module.hdb_node.hdb-sid
  hana-database-info           = module.hdb_node.hana-database-info
  nics-scs                     = module.app_tier.nics-scs
  nics-app                     = module.app_tier.nics-app
  nics-web                     = module.app_tier.nics-web
}
