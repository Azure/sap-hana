/*
Description:

  Generate post-deployment scripts.
*/

resource "local_file" "scp" {
  content = templatefile("${path.module}/deployer_scp.tmpl", {
    deployer-ppk = var.sshkey.path_to_private_key,
    deployers    = local.deployers,
    deployer-ips = azurerm_public_ip.deployer[*].ip_address
  })
  filename             = "${terraform.workspace}/post_deployment.sh"
  file_permission      = "0770"
  directory_permission = "0770"
}

