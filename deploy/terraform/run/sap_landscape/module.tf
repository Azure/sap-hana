/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  source                     = "../../terraform-units/modules/sap_landscape"
  is_single_node_hana        = "true"
  application                = var.application
  databases                  = var.databases
  infrastructure             = var.infrastructure
  jumpboxes                  = var.jumpboxes
  options                    = local.options
  software                   = var.software
  ssh-timeout                = var.ssh-timeout
  sshkey                     = var.sshkey
  naming                     = module.sap_namegenerator.naming
  service_principal          = local.service_principal
  deployer_tfstate           = data.terraform_remote_state.deployer.outputs
}

module "sap_namegenerator" {
  source           = "../../terraform-units/modules/sap_namegenerator"
  environment      = var.infrastructure.environment
  location         = var.infrastructure.region
  codename         = lower(try(var.infrastructure.codename, ""))
  random_id        = module.sap_landscape.random_id
  sap_vnet_name    = local.vnet_sap_name_part
}
