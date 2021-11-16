/*
  Description:
  Setup common infrastructure
*/


module "sap_namegenerator" {
  source           = "../../terraform-units/modules/sap_namegenerator"
  environment      = local.infrastructure.environment
  location         = local.infrastructure.region
  codename         = lower(try(local.infrastructure.codename, ""))
  random_id        = module.common_infrastructure.random_id
  sap_vnet_name    = local.vnet_logical_name
  sap_sid          = local.sap_sid
  db_sid           = local.db_sid
  app_ostype       = try(local.application.os.os_type, "LINUX")
  anchor_ostype    = upper(try(local.anchor_vms.os.os_type, "LINUX"))
  db_ostype        = try(local.databases[0].os.os_type, "LINUX")
  db_server_count  = var.database_server_count
  app_server_count = try(local.application.application_server_count, 0)
  web_server_count = try(local.application.webdispatcher_count, 0)
  scs_server_count = local.application.scs_high_availability ? 2 * local.application.scs_server_count : local.application.scs_server_count
  app_zones        = []
  scs_zones        = try(local.application.scs_zones, [])
  web_zones        = try(local.application.web_zones, [])
  db_zones         = try(local.databases[0].zones, [])
  resource_offset  = try(var.options.resource_offset, 0)
  custom_prefix    = var.custom_prefix
}

module "common_infrastructure" {
  source = "../../terraform-units/modules/sap_system/common_infrastructure"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  is_single_node_hana                = "true"
  application                        = local.application
  databases                          = local.databases
  infrastructure                     = local.infrastructure
  options                            = local.options
  key_vault                          = local.key_vault
  naming                             = module.sap_namegenerator.naming
  service_principal                  = local.use_spn ? local.service_principal : local.account
  deployer_tfstate                   = length(var.deployer_tfstate_key) > 0 ? data.terraform_remote_state.deployer[0].outputs : null
  landscape_tfstate                  = data.terraform_remote_state.landscape.outputs
  custom_disk_sizes_filename         = var.db_disk_sizes_filename
  authentication                     = local.authentication
  terraform_template_version         = var.terraform_template_version
  deployment                         = var.deployment
  license_type                       = var.license_type
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults
  anf_transport_volume_size          = var.anf_transport_volume_size
  anf_sapmnt_volume_size             = var.anf_sapmnt_volume_size
  use_ANF                            = var.use_ANF
  custom_prefix                      = var.custom_prefix
}

# // Create HANA database nodes
module "hdb_node" {
  source = "../../terraform-units/modules/sap_system/hdb_node"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  depends_on = [module.common_infrastructure]
  order_deployment = local.db_zonal_deployment ? (
    module.app_tier.scs_vm_ids[0]
  ) : (null)
  databases                                    = local.databases
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  sid_kv_user_id                               = module.common_infrastructure.sid_kv_user_id
  naming                                       = module.sap_namegenerator.naming
  custom_disk_sizes_filename                   = var.db_disk_sizes_filename
  admin_subnet                                 = module.common_infrastructure.admin_subnet
  db_subnet                                    = module.common_infrastructure.db_subnet
  storage_subnet                               = module.common_infrastructure.storage_subnet
  anchor_vm                                    = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  sap_sid                                      = local.sap_sid
  db_asg_id                                    = module.common_infrastructure.db_asg_id
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  hana_dual_nics                               = var.hana_dual_nics
  database_vm_names                            = var.database_vm_names
  database_vm_db_nic_ips                       = var.database_vm_db_nic_ips
  database_vm_admin_nic_ips                    = var.database_vm_admin_nic_ips
  database_vm_storage_nic_ips                  = var.database_vm_storage_nic_ips
  database_server_count = upper(try(local.databases[0].platform, "HANA")) == "HANA" ? (
    local.databases[0].high_availability ? 2 * var.database_server_count : var.database_server_count) : (
    0
  )
}

# // Create Application Tier nodes
module "app_tier" {
  source = "../../terraform-units/modules/sap_system/app_tier"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  order_deployment = local.db_zonal_deployment ? (
    "") : (
    coalesce(try(module.hdb_node.hdb_vms[0], ""), try(module.anydb_node.anydb_vms[0], ""))
  )

  application                                  = local.application
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  sid_kv_user_id                               = module.common_infrastructure.sid_kv_user_id
  naming                                       = module.sap_namegenerator.naming
  admin_subnet                                 = module.common_infrastructure.admin_subnet
  custom_disk_sizes_filename                   = var.app_disk_sizes_filename
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  route_table_id                               = module.common_infrastructure.route_table_id
  firewall_id                                  = module.common_infrastructure.firewall_id
  sap_sid                                      = local.sap_sid
  landscape_tfstate                            = data.terraform_remote_state.landscape.outputs
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  network_location                             = module.common_infrastructure.network_location
  network_resource_group                       = module.common_infrastructure.network_resource_group
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
}

# // Create anydb database nodes
module "anydb_node" {
  source = "../../terraform-units/modules/sap_system/anydb_node"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  depends_on = [module.common_infrastructure]
  order_deployment = local.db_zonal_deployment ? (
    module.app_tier.scs_vm_ids[0]
  ) : (null)
  databases                                    = local.databases
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  sid_kv_user_id                               = module.common_infrastructure.sid_kv_user_id
  naming                                       = module.sap_namegenerator.naming
  custom_disk_sizes_filename                   = var.db_disk_sizes_filename
  admin_subnet                                 = module.common_infrastructure.admin_subnet
  db_subnet                                    = module.common_infrastructure.db_subnet
  anchor_vm                                    = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  sap_sid                                      = local.sap_sid
  db_asg_id                                    = module.common_infrastructure.db_asg_id
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  database_vm_names                            = var.database_vm_names
  database_vm_db_nic_ips                       = var.database_vm_db_nic_ips
  database_vm_admin_nic_ips                    = var.database_vm_admin_nic_ips
  database_vm_storage_nic_ips                  = var.database_vm_storage_nic_ips
  database_server_count = upper(try(local.databases[0].platform, "HANA")) == "HANA" ? (
    0) : (
    local.databases[0].high_availability ? 2 * var.database_server_count : var.database_server_count
  )
}
# // Generate output files
module "output_files" {
  source = "../../terraform-units/modules/sap_system/output_files"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  databases             = local.databases
  infrastructure        = local.infrastructure
  authentication        = local.authentication
  authentication_type   = try(local.application.authentication.type, "key")
  iscsi_private_ip      = module.common_infrastructure.iscsi_private_ip
  nics_dbnodes_admin    = module.hdb_node.nics_dbnodes_admin
  nics_dbnodes_db       = module.hdb_node.nics_dbnodes_db
  loadbalancers         = module.hdb_node.loadbalancers
  sap_sid               = local.sap_sid
  db_sid                = local.db_sid
  nics_scs              = module.app_tier.nics_scs
  nics_app              = module.app_tier.nics_app
  nics_web              = module.app_tier.nics_web
  nics_anydb            = module.anydb_node.nics_anydb
  nics_scs_admin        = module.app_tier.nics_scs_admin
  nics_app_admin        = module.app_tier.nics_app_admin
  nics_web_admin        = module.app_tier.nics_web_admin
  nics_anydb_admin      = module.anydb_node.nics_anydb_admin
  anydb_loadbalancers   = module.anydb_node.anydb_loadbalancers
  random_id             = module.common_infrastructure.random_id
  landscape_tfstate     = data.terraform_remote_state.landscape.outputs
  naming                = module.sap_namegenerator.naming
  app_tier_os_types     = module.app_tier.app_tier_os_types
  sid_kv_user_id        = module.common_infrastructure.sid_kv_user_id
  disks                 = distinct(compact(concat(module.hdb_node.dbtier_disks, module.anydb_node.dbtier_disks, module.app_tier.apptier_disks)))
  use_local_credentials = module.common_infrastructure.use_local_credentials
  scs_ha                = module.app_tier.scs_ha
  db_ha                 = upper(try(local.databases[0].platform, "HANA")) == "HANA" ? module.hdb_node.db_ha : module.anydb_node.db_ha
  ansible_user          = module.common_infrastructure.sid_username
  scs_lb_ip             = module.app_tier.scs_lb_ip
  db_lb_ip              = upper(try(local.databases[0].platform, "HANA")) == "HANA" ? module.hdb_node.db_lb_ip : module.anydb_node.db_lb_ip
  database_admin_ips    = upper(try(local.databases[0].platform, "HANA")) == "HANA" ? module.hdb_node.db_ip : module.anydb_node.anydb_db_ip #TODO Change to use Admin IP
  sap_mnt               = module.common_infrastructure.sapmnt_path
  sap_transport         = module.common_infrastructure.saptransport_path
  ers_lb_ip             = module.app_tier.ers_lb_ip
  bom_name              = var.bom_name
  scs_instance_number   = var.scs_instance_number
  ers_instance_number   = var.ers_instance_number
  platform              = upper(try(local.databases[0].platform, "HANA"))
  db_auth_type          = try(local.databases[0].authentication.type, "key")
  tfstate_resource_id   = var.tfstate_resource_id

}
