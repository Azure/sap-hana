/*
  Description:
  Setup sap library
*/
module "sap_library" {
  source = "../../terraform-units/modules/sap_library"
  # commenting out for fixing issues
  #  providers = {
  #    azurerm.main     = azurerm
  #    azurerm.deployer = azurerm.deployer
  #  }
  infrastructure          = local.infrastructure
  storage_account_sapbits = local.storage_account_sapbits
  storage_account_tfstate = local.storage_account_tfstate
  software                = var.software
  deployer                = local.deployer
  key_vault               = local.key_vault
  service_principal       = local.service_principal
  deployer_tfstate        = try(data.terraform_remote_state.deployer[0].outputs, [])
  naming                  = module.sap_namegenerator.naming
  dns_label               = var.dns_label
  use_private_endpoint    = var.use_private_endpoint
}

module "sap_namegenerator" {
  source               = "../../terraform-units/modules/sap_namegenerator"
  environment          = local.infrastructure.environment
  codename             = try(local.infrastructure.codename, "")
  location             = local.infrastructure.region
  deployer_environment = try(local.deployer.environment, local.infrastructure.environment)
  deployer_location    = try(local.deployer.region, local.infrastructure.region)
  management_vnet_name = local.deployer.vnet
  random_id            = module.sap_library.random_id
}
