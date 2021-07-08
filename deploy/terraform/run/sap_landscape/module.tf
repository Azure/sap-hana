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
  diagnostics_storage_account = local.diagnostics_storage_account
  witness_storage_account     = local.witness_storage_account

  use_deployer = length(var.deployer_tfstate_key) > 0
}

module "sap_namegenerator" {
  source             = "../../terraform-units/modules/sap_namegenerator"
  environment        = local.infrastructure.environment
  location           = local.infrastructure.region
  iscsi_server_count = local.infrastructure.iscsi.iscsi_count
  codename           = lower(try(local.infrastructure.codename, ""))
  random_id          = module.sap_landscape.random_id
  sap_vnet_name      = local.vnet_logical_name
}
