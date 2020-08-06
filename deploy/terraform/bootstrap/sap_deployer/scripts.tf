/*
Description:

  Generate post-deployment scripts.
*/

resource "local_file" "scp" {
  content = templatefile("${path.module}/deployer_scp.tmpl", {
    deployer-ppk = var.sshkey.path_to_private_key,
    deployers    = module.sap_deployer.deployers,
    deployer-ips = module.sap_deployer.deployer_pip[*].ip_address
  })
  filename             = "${terraform.workspace}/post_deployment.sh"
  file_permission      = "0660"
  directory_permission = "0770"
}

