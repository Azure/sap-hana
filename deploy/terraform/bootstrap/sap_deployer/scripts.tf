/*
Description:

  Generate post-deployment scripts.

*/

resource "local_file" "scp" {
  content = templatefile("${path.module}/deployer_scp.tmpl", {
    user_vault_name = module.sap_deployer.user_vault_name,
    ppk_name        = module.sap_deployer.ppk_secret_name,
    pwd_name        = module.sap_deployer.pwd_secret_name,
    deployers       = module.sap_deployer.deployers,
    deployer-ips    = local.enable_deployer_public_ip ? module.sap_deployer.deployer_pip[*].ip_address : module.sap_deployer.deployer_private_ip_address
  })
  filename             = "${path.cwd}/post_deployment.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}
