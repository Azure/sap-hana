/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  source            = "../../terraform-units/modules/sap_landscape"
  infrastructure    = var.infrastructure
  options           = local.options
  ssh-timeout       = var.ssh-timeout
  sshkey            = var.sshkey
  naming            = module.sap_namegenerator.naming
  service_principal = local.service_principal
  deployer_tfstate  = data.terraform_remote_state.deployer.outputs
}

module "sap_namegenerator" {
  source             = "../../terraform-units/modules/sap_namegenerator"
  environment        = var.infrastructure.environment
  location           = var.infrastructure.region
  iscsi_server_count = local.iscsi_count
  codename           = lower(try(var.infrastructure.codename, ""))
  random_id          = module.sap_landscape.random_id
  sap_vnet_name      = local.vnet_sap_name_part
}
