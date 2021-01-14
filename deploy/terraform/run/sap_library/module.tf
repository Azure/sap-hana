/*
  Description:
  Setup sap library
*/
module "sap_library" {
  source                  = "../../terraform-units/modules/sap_library"
  infrastructure          = var.infrastructure
  storage_account_sapbits = var.storage_account_sapbits
  storage_account_tfstate = var.storage_account_tfstate
  software                = var.software
  deployer                = var.deployer
  key_vault               = var.key_vault
  service_principal       = local.service_principal
  deployer_tfstate        = data.terraform_remote_state.deployer
  naming                  = module.sap_namegenerator.naming
}

module sap_namegenerator {
  source               = "../../terraform-units/modules/sap_namegenerator"
  environment          = var.infrastructure.environment
  deployer_environment = try(var.deployer.environment, var.infrastructure.environment)
  management_vnet_name = var.deployer.vnet
  location             = var.infrastructure.region
  deployer_location    = try(var.deployer.region, var.infrastructure.region)
  random_id            = module.sap_library.random_id
}
