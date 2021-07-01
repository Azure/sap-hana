/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source                          = "../../terraform-units/modules/sap_deployer"
  infrastructure                  = var.infrastructure
  deployers                       = var.deployers
  options                         = var.options
  ssh-timeout                     = var.ssh-timeout
  authentication                  = var.authentication
  key_vault                       = var.key_vault
  naming                          = module.sap_namegenerator.naming
  firewall_deployment             = var.firewall_deployment
  assign_subscription_permissions = var.assign_subscription_permissions
}

module "sap_namegenerator" {
  source               = "../../terraform-units/modules/sap_namegenerator"
  environment          = lower(local.infrastructure.environment)
  deployer_environment = lower(local.infrastructure.environment)
  location             = lower(local.infrastructure.region)
  codename             = lower(local.infrastructure.codename)
  management_vnet_name = local.vnet_mgmt_name_part
  random_id            = module.sap_deployer.random_id
  deployer_vm_count    = local.deployer_vm_count
}
