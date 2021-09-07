/*
Description:

  Configures the Deployer after creation.

*/

// Prepare deployer with pre-installed softwares if pip is created
resource "null_resource" "prepare-deployer" {
  depends_on = [azurerm_linux_virtual_machine.deployer]
  count      = local.enable_deployer_public_ip ? length(local.deployers) : 0

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.deployers[count.index].authentication.username
    private_key = local.deployers[count.index].authentication.type == "key" ? local.deployers[count.index].authentication.sshkey.private_key : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  provisioner "file" {
    content = templatefile(format("%s/templates/configure_deployer.sh.tmpl", path.module), {
      tfversion       = "0.14.7",
      rg_name         = local.rg_name,
      client_id       = azurerm_user_assigned_identity.deployer.client_id,
      subscription_id = data.azurerm_subscription.primary.subscription_id,
      tenant_id       = data.azurerm_subscription.primary.tenant_id
      }
    )

    destination = "/tmp/configure_deployer.sh"
  }

  provisioner "remote-exec" {
    inline = local.deployers[count.index].os.source_image_id != "" ? [] : [
      //
      // Set useful shell options
      //
      "set -o xtrace",
      "set -o verbose",
      "set -o errexit",

      //
      // Make configure_deployer.sh executable and run it
      //
      "chmod +x /tmp/configure_deployer.sh",
      "/tmp/configure_deployer.sh"
    ]
  }

}

resource "local_file" "configure_deployer" {
  count = local.enable_deployer_public_ip ? 0 : length(local.deployers)
  content = templatefile(format("%s/templates/configure_deployer.sh.tmpl", path.module), {
    tfversion       = "0.14.7",
    rg_name         = local.rg_name,
    client_id       = azurerm_user_assigned_identity.deployer.client_id,
    subscription_id = data.azurerm_subscription.primary.subscription_id,
    tenant_id       = data.azurerm_subscription.primary.tenant_id
    }
  )
  filename             = format("%s/configure_deployer.sh", path.cwd)
  file_permission      = "0660"
  directory_permission = "0770"
}
