/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  providers = {
    azurerm.main     = azurerm.main
    azurerm.deployer = azurerm.deployer
  }
  source                      = "../../terraform-units/modules/sap_landscape"
  infrastructure              = local.infrastructure
  options                     = local.options
  authentication              = local.authentication
  naming                      = module.sap_namegenerator.naming
  service_principal           = local.use_spn ? local.service_principal : local.account
  key_vault                   = var.key_vault
  deployer_tfstate            = try(data.terraform_remote_state.deployer[0].outputs, [])
  diagnostics_storage_account = var.diagnostics_storage_account
  witness_storage_account     = var.witness_storage_account
  use_deployer                = length(var.deployer_tfstate_key) > 0
  ANF_settings                = local.ANF_settings
  create_spn                  = local.options.create_fencing_spn
  dns_label                   = var.dns_label
  dns_resource_group_name     = length(var.dns_resource_group_name) > 0 ? var.dns_resource_group_name : local.saplib_resource_group_name
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults

}

module "sap_namegenerator" {
  source             = "../../terraform-units/modules/sap_namegenerator"
  environment        = local.infrastructure.environment
  location           = local.infrastructure.region
  iscsi_server_count = try(local.infrastructure.iscsi.iscsi_count, 0)
  codename           = lower(try(local.infrastructure.codename, ""))
  random_id          = module.sap_landscape.random_id
  sap_vnet_name      = local.vnet_logical_name
}

