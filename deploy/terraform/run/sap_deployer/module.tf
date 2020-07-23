/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source         = "../../terraform-units/modules/sap_deployer/"
  infrastructure = var.infrastructure
  deployers      = var.deployers
  options        = var.options
  ssh-timeout    = var.ssh-timeout
  sshkey         = var.sshkey
}
