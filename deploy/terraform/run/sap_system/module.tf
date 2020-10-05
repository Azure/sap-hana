/*
  Description:
  Setup common infrastructure
*/

module "deployer" {
  source            = "../../terraform-units/modules/sap_system/deployer"
  application       = var.application
  databases         = var.databases
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  options           = var.options
  software          = var.software
  ssh-timeout       = var.ssh-timeout
  sshkey            = var.sshkey
  naming            = module.sap_namegenerator.naming
}

module "saplibrary" {
  source         = "../../terraform-units/modules/sap_system/saplibrary"
  application    = var.application
  databases      = var.databases
  infrastructure = var.infrastructure
  jumpboxes      = var.jumpboxes
  options        = var.options
  software       = var.software
  ssh-timeout    = var.ssh-timeout
  sshkey         = var.sshkey
  naming         = module.sap_namegenerator.naming
}


module "common_infrastructure" {
  source              = "../../terraform-units/modules/sap_system/common_infrastructure"
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
  vnet-mgmt           = module.deployer.vnet-mgmt
  subnet-mgmt         = module.deployer.subnet-mgmt
  nsg-mgmt            = module.deployer.nsg-mgmt
  naming              = module.sap_namegenerator.naming
}

module "sap_namegenerator" {
  source        = "../../terraform-units/modules/sap_namegenerator"
  environment   = lower(try(var.infrastructure.environment, ""))
  location      = try(var.infrastructure.region, "")
  codename      = lower(try(var.infrastructure.codename, ""))
  random_id     = module.common_infrastructure.random_id
  sap_vnet_name = local.vnet_sap_name_part
  sap_sid       = local.sap_sid
  db_sid        = local.db_sid
  app_ostype    = local.app_ostype
  db_ostype     = local.db_ostype
  /////////////////////////////////////////////////////////////////////////////////////
  // The naming module creates a list of servers names that is app_server_count
  // for database servers the list is 2 * db_server_count. 
  // The first db_server_count items are for single node
  // The the second db_server_count items are for ha
  /////////////////////////////////////////////////////////////////////////////////////
  db_server_count  = local.db_server_count
  app_server_count = local.app_server_count
  web_server_count = local.webdispatcher_count
  scs_server_count = local.scs_server_count
}

// Create Jumpboxes
module "jumpbox" {
  source            = "../../terraform-units/modules/sap_system/jumpbox"
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
  random-id         = module.common_infrastructure.random_id
  deployer-uai      = module.deployer.deployer-uai
}

// Create HANA database nodes
module "hdb_node" {
  source           = "../../terraform-units/modules/sap_system/hdb_node"
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
  naming           = module.sap_namegenerator.naming
}

// Create Application Tier nodes
module "app_tier" {
  source           = "../../terraform-units/modules/sap_system/app_tier"
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
  vnet-sap         = module.common_infrastructure.vnet-sap
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
  ppg              = module.common_infrastructure.ppg
  naming           = module.sap_namegenerator.naming
}

// Create anydb database nodes
module "anydb_node" {
  source           = "../../terraform-units/modules/sap_system/anydb_node"
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
  naming           = module.sap_namegenerator.naming
}

// Generate output files
module "output_files" {
  source                       = "../../terraform-units/modules/sap_system/output_files"
  application                  = var.application
  databases                    = var.databases
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  options                      = local.options
  software                     = var.software
  ssh-timeout                  = var.ssh-timeout
  sshkey                       = var.sshkey
  storage-sapbits              = module.saplibrary.saplibrary
  file_share_name              = module.saplibrary.file_share_name
  storagecontainer-sapbits     = module.saplibrary.storagecontainer-sapbits
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
  nics-anydb                   = module.anydb_node.nics-anydb
  any-database-info            = module.anydb_node.any-database-info
  anydb-loadbalancers          = module.anydb_node.anydb-loadbalancers
  deployers                    = module.deployer.import_deployer
  random_id                    = module.common_infrastructure.random_id
}
