/*
  Description:
  Setup common infrastructure
*/
module "common_infrastructure" {
<<<<<<< HEAD
  source              = "../modules/common_infrastructure"
=======
<<<<<<<< HEAD:deploy/terraform/run/sap_landscape/module.tf
  source              = "../modules/common_infrastructure"
========
  source              = "../../run/modules/common_infrastructure"
>>>>>>>> restructure the codebase (#659):deploy/terraform/run/module.tf
>>>>>>> restructure the codebase (#659)
  is_single_node_hana = "true"
  application         = var.application
  databases           = var.databases
  infrastructure      = var.infrastructure
  jumpboxes           = var.jumpboxes
  options             = local.options
  software            = var.software
  ssh-timeout         = var.ssh-timeout
  sshkey              = var.sshkey
  subnet-sap-admin    = module.hdb_node.subnet-sap-admin
}

// Create Jumpboxes and RTI box
module "jumpbox" {
<<<<<<< HEAD
  source            = "../modules/jumpbox"
=======
<<<<<<<< HEAD:deploy/terraform/run/sap_landscape/module.tf
  source            = "../modules/jumpbox"
========
  source            = "../../run/modules/jumpbox"
>>>>>>>> restructure the codebase (#659):deploy/terraform/run/module.tf
>>>>>>> restructure the codebase (#659)
  application       = var.application
  databases         = var.databases
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  options           = local.options
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

// Create HANA database nodes
module "hdb_node" {
<<<<<<< HEAD
  source           = "../modules/hdb_node"
=======
<<<<<<<< HEAD:deploy/terraform/run/sap_landscape/module.tf
  source           = "../modules/hdb_node"
========
  source           = "../../run/modules/hdb_node"
>>>>>>>> restructure the codebase (#659):deploy/terraform/run/module.tf
>>>>>>> restructure the codebase (#659)
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = local.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  subnet-mgmt      = module.common_infrastructure.subnet-mgmt
  nsg-mgmt         = module.common_infrastructure.nsg-mgmt
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
}

<<<<<<< HEAD
// Create Application Tier nodes
module "app_tier" {
  source           = "../modules/app_tier"
=======
<<<<<<< HEAD:deploy/terraform/bootstrap/sap_landscape/module.tf
// Create anydb database nodes
module "anydb_node" {
  source           = "../../run/modules/anydb_node"
>>>>>>> restructure the codebase (#659)
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
<<<<<<< HEAD
  options          = local.options
=======
  options          = var.options
>>>>>>> restructure the codebase (#659)
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
<<<<<<< HEAD
  subnet-mgmt      = module.common_infrastructure.subnet-mgmt
=======
>>>>>>> restructure the codebase (#659)
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
}

<<<<<<< HEAD
// Create anydb database nodes
module "anydb_node" {
  source           = "./modules/anydb_node"
=======
=======
>>>>>>> Restructure the codebase (#657):deploy/terraform/run/module.tf
// Create Application Tier nodes
module "app_tier" {
<<<<<<<< HEAD:deploy/terraform/run/sap_landscape/module.tf
  source           = "../modules/app_tier"
========
  source           = "../../run/modules/app_tier"
>>>>>>>> restructure the codebase (#659):deploy/terraform/run/module.tf
>>>>>>> restructure the codebase (#659)
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
<<<<<<< HEAD
  options          = var.options
=======
  options          = local.options
>>>>>>> restructure the codebase (#659)
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
<<<<<<< HEAD
=======
  subnet-mgmt      = module.common_infrastructure.subnet-mgmt
>>>>>>> restructure the codebase (#659)
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
}

// Generate output files
module "output_files" {
<<<<<<< HEAD
  source                       = "../modules/output_files"
=======
<<<<<<<< HEAD:deploy/terraform/run/sap_landscape/module.tf
  source                       = "../modules/output_files"
========
  source                       = "../../run/modules/output_files"
>>>>>>>> restructure the codebase (#659):deploy/terraform/run/module.tf
>>>>>>> restructure the codebase (#659)
  application                  = var.application
  databases                    = var.databases
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  options                      = local.options
  software                     = var.software
  ssh-timeout                  = var.ssh-timeout
  sshkey                       = var.sshkey
  storage-sapbits              = module.common_infrastructure.storage-sapbits
  nics-iscsi                   = module.common_infrastructure.nics-iscsi
  infrastructure_w_defaults    = module.common_infrastructure.infrastructure_w_defaults
  software_w_defaults          = module.common_infrastructure.software_w_defaults
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
<<<<<<< HEAD
  nics-anydb                   = module.anydb_node.nics-anydb
  any-database-info            = module.anydb_node.any-database-info
  anydb-loadbalancers          = module.anydb_node.anydb-loadbalancers

=======
>>>>>>> restructure the codebase (#659)
}
