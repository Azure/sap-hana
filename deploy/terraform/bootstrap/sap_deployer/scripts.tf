/*
Description:

  Generate post-deployment scripts.

*/

resource "local_file" "scp" {
  content = templatefile(format("%s/deployer_scp.tmpl",path.module), {
    user_vault_name = module.sap_deployer.user_vault_name,
    ppk_name        = module.sap_deployer.ppk_secret_name,
    pwd_name        = module.sap_deployer.pwd_secret_name,
    deployers       = module.sap_deployer.deployers,
    deployer-ips    = local.enable_deployer_public_ip ? module.sap_deployer.deployer_pip[*].ip_address : module.sap_deployer.deployer_private_ip_address,
    deployer-rgs    = module.sap_deployer.deployer_rg_name
  })
  filename             = format("%s/post_deployment.sh",path.cwd)
  file_permission      = "0770"
  directory_permission = "0770"
}
