/*
  Description:
  Setup common infrastructure
*/


module "sap_namegenerator" {
  source           = "../../terraform-units/modules/sap_namegenerator"
  environment      = var.infrastructure.environment
  location         = var.infrastructure.region
  codename         = lower(try(var.infrastructure.codename, ""))
  random_id        = module.common_infrastructure.random_id
  sap_vnet_name    = local.vnet_logical_name
  sap_sid          = local.sap_sid
  db_sid           = local.db_sid
  app_ostype       = local.app_ostype
  anchor_ostype    = local.anchor_ostype
  db_ostype        = local.db_ostype
  db_server_count  = local.db_server_count
  app_server_count = local.app_server_count
  web_server_count = local.webdispatcher_count
  scs_server_count = local.scs_server_count
  app_zones        = local.app_zones
  scs_zones        = local.scs_zones
  web_zones        = local.web_zones
  db_zones         = local.db_zones
  resource_offset  = try(var.options.resource_offset, 0)
}

module "common_infrastructure" {
  source = "../../terraform-units/modules/sap_system/common_infrastructure"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  is_single_node_hana        = "true"
  application                = var.application
  databases                  = var.databases
  infrastructure             = var.infrastructure
  options                    = var.options
  key_vault                  = var.key_vault
  naming                     = module.sap_namegenerator.naming
  service_principal          = local.service_principal
  deployer_tfstate           = length(local.deployer_tfstate_key) > 0 ? data.terraform_remote_state.deployer[0].outputs : null
  landscape_tfstate          = data.terraform_remote_state.landscape.outputs
  custom_disk_sizes_filename = var.db_disk_sizes_filename
  authentication             = var.authentication
  terraform_template_version = var.terraform_template_version
  deployment                 = var.deployment
}

// Create HANA database nodes
module "hdb_node" {
  source = "../../terraform-units/modules/sap_system/hdb_node"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  databases                  = var.databases
  infrastructure             = var.infrastructure
  options                    = var.options
  resource_group             = module.common_infrastructure.resource_group
  vnet_sap                   = module.common_infrastructure.vnet_sap
  storage_bootdiag_endpoint  = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                        = module.common_infrastructure.ppg
  sid_kv_user_id             = module.common_infrastructure.sid_kv_user_id
  naming                     = module.sap_namegenerator.naming
  custom_disk_sizes_filename = var.db_disk_sizes_filename
  admin_subnet               = module.common_infrastructure.admin_subnet
  db_subnet                  = module.common_infrastructure.db_subnet
  storage_subnet             = module.common_infrastructure.storage_subnet
  anchor_vm                  = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password               = module.common_infrastructure.sid_password
  sid_username               = module.common_infrastructure.sid_username
  sdu_public_key             = module.common_infrastructure.sdu_public_key
  sap_sid                    = local.sap_sid
  db_asg_id                  = module.common_infrastructure.db_asg_id
  terraform_template_version = var.terraform_template_version
  deployment                 = var.deployment
}

// Create Application Tier nodes
module "app_tier" {
  source = "../../terraform-units/modules/sap_system/app_tier"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  application                = var.application
  infrastructure             = var.infrastructure
  options                    = var.options
  resource_group             = module.common_infrastructure.resource_group
  vnet_sap                   = module.common_infrastructure.vnet_sap
  storage_bootdiag_endpoint  = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                        = module.common_infrastructure.ppg
  sid_kv_user_id             = module.common_infrastructure.sid_kv_user_id
  naming                     = module.sap_namegenerator.naming
  admin_subnet               = module.common_infrastructure.admin_subnet
  custom_disk_sizes_filename = var.app_disk_sizes_filename
  anydb_vm_ids               = module.anydb_node.anydb_vms // Workaround to create dependency from anchor to db to app
  hdb_vm_ids                 = module.hdb_node.hdb_vms
  sid_password               = module.common_infrastructure.sid_password
  sid_username               = module.common_infrastructure.sid_username
  sdu_public_key             = module.common_infrastructure.sdu_public_key
  route_table_id             = module.common_infrastructure.route_table_id
  firewall_id                = module.common_infrastructure.firewall_id
  sap_sid                    = local.sap_sid
  landscape_tfstate          = data.terraform_remote_state.landscape.outputs
  terraform_template_version = var.terraform_template_version
  deployment                 = var.deployment

}

// Create anydb database nodes
module "anydb_node" {
  source = "../../terraform-units/modules/sap_system/anydb_node"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  databases                  = var.databases
  infrastructure             = var.infrastructure
  options                    = var.options
  resource_group             = module.common_infrastructure.resource_group
  vnet_sap                   = module.common_infrastructure.vnet_sap
  storage_bootdiag_endpoint  = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                        = module.common_infrastructure.ppg
  sid_kv_user_id             = module.common_infrastructure.sid_kv_user_id
  naming                     = module.sap_namegenerator.naming
  custom_disk_sizes_filename = var.db_disk_sizes_filename
  admin_subnet               = module.common_infrastructure.admin_subnet
  db_subnet                  = module.common_infrastructure.db_subnet
  anchor_vm                  = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password               = module.common_infrastructure.sid_password
  sid_username               = module.common_infrastructure.sid_username
  sdu_public_key             = module.common_infrastructure.sdu_public_key
  sap_sid                    = local.sap_sid
  db_asg_id                  = module.common_infrastructure.db_asg_id
  terraform_template_version = var.terraform_template_version
  deployment                 = var.deployment

}

// Generate output files
module "output_files" {
  source = "../../terraform-units/modules/sap_system/output_files"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  application               = module.app_tier.application
  databases                 = var.databases
  infrastructure            = var.infrastructure
  options                   = var.options
  software                  = var.software
  ssh-timeout               = var.ssh-timeout
  authentication            = var.authentication
  iscsi_private_ip          = module.common_infrastructure.iscsi_private_ip
  infrastructure_w_defaults = module.common_infrastructure.infrastructure_w_defaults
  nics_dbnodes_admin        = module.hdb_node.nics_dbnodes_admin
  nics_dbnodes_db           = module.hdb_node.nics_dbnodes_db
  loadbalancers             = module.hdb_node.loadbalancers
  hdb_sid                   = module.hdb_node.hdb_sid
  hana_database_info        = module.hdb_node.hana_database_info
  nics_scs                  = module.app_tier.nics_scs
  nics_app                  = module.app_tier.nics_app
  nics_web                  = module.app_tier.nics_web
  nics_anydb                = module.anydb_node.nics_anydb
  nics_scs_admin            = module.app_tier.nics_scs_admin
  nics_app_admin            = module.app_tier.nics_app_admin
  nics_web_admin            = module.app_tier.nics_web_admin
  nics_anydb_admin          = module.anydb_node.nics_anydb_admin
  any_database_info         = module.anydb_node.any_database_info
  anydb_loadbalancers       = module.anydb_node.anydb_loadbalancers
  random_id                 = module.common_infrastructure.random_id
  landscape_tfstate         = data.terraform_remote_state.landscape.outputs
  tfstate_resource_id       = var.tfstate_resource_id
  naming                    = module.sap_namegenerator.naming
  app_tier_os_types         = module.app_tier.app_tier_os_types
  sid_kv_user_id            = module.common_infrastructure.sid_kv_user_id
  disks                     = distinct(compact(concat(module.hdb_node.dbtier_disks, module.anydb_node.dbtier_disks, module.app_tier.apptier_disks)))
  use_local_credentials     = module.common_infrastructure.use_local_credentials

}
