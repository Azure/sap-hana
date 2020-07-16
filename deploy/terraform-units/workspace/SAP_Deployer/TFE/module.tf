/*
Description:

  Module to deploy deployer(s).
*/
module "sap_deployer" {
  source         = "../../../modules/sap_deployer"
  infrastructure = var.infrastructure
  jumpboxes      = var.jumpboxes
  options        = var.options
  ssh-timeout    = var.ssh-timeout
  sshkey         = var.sshkey
}
