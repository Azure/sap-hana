/*
  Description:
    1. Run ansible playbook automatically on first deployer if ansible_execution set to true
*/

resource "null_resource" "ansible_playbook" {
  count      = local.ansible_execution ? 1 : 0
  depends_on = [module.hdb_node.dbnode_data_disk_att]

  connection {
    type        = "ssh"
    host        = local.import_deployer[0].public_ip_address
    user        = local.import_deployer[0].authentication.username
    private_key = local.import_deployer[0].authentication.type == "key" ? file(local.import_deployer[0].authentication.sshkey.path_to_private_key) : null
    password    = lookup(local.import_deployer[0].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  // Run Ansible Playbook on deployer if ansible_execution set to true
  provisioner "remote-exec" {
    inline = [
      # Registers the current deployment state with Azure's Metadata Service (IMDS)
      "curl -i -H \"Metadata: \"true\"\" -H \"user-agent: SAP AutoDeploy/${var.auto-deploy-version}; scenario=${var.scenario}; deploy-status=Terraform_finished\" http://169.254.169.254/metadata/instance?api-version=${var.api-version}",
      "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES",
      "source ~/export-clustering-sp-details.sh",
      "ansible-playbook -i ${path.cwd}/ansible_config_files/hosts.yml ~/sap-hana/deploy/ansible/sap_playbook.yml"
    ]
  }
}
