/*
  Description:
    1. Upload inventory files to deployer(s)
    2. Run ansible playbook automatically on first deployer if ansible_execution set to true
*/

resource "null_resource" "prepare_deployer" {
  depends_on = [module.output_files.ansible-inventory, module.output_files.output-json]
  count      = length(local.import_deployer)
  triggers = {
    hosts     = sha1(local.file_hosts)
    hosts_yml = sha1(local.file_hosts_yml)
    output    = sha1(local.file_output)
  }

  connection {
    type        = "ssh"
    host        = local.import_deployer[count.index].public_ip_address
    user        = local.import_deployer[count.index].authentication.username
    private_key = local.import_deployer[count.index].authentication.type == "key" ? file(local.import_deployer[count.index].authentication.sshkey.path_to_private_key) : null
    password    = lookup(local.import_deployer[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  // Create path if not exists
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${local.import_deployer[count.index].authentication.username}/${local.ansible_path}"
    ]
  }

  // Copies output.json and inventory file for ansbile on deployer(s).
  provisioner "file" {
    source      = "${terraform.workspace}/ansible_config_files/"
    destination = "/home/${local.import_deployer[count.index].authentication.username}/${local.ansible_path}/"
  }

  // Copies Clustering Service Principal for ansbile on deployer(s).
  provisioner "file" {
    /*
      Note: We provide a default empty clustering auth script content so this provisioner succeeds.
      Later in the execution, the script is sourced, but will have no impact if it has been defaulted
    */
    content     = fileexists("${terraform.workspace}/export-clustering-sp-details.sh") ? file("${terraform.workspace}/export-clustering-sp-details.sh") : "# default empty clustering auth script"
    destination = "/home/${local.import_deployer[count.index].authentication.username}/${local.ansible_path}/export-clustering-sp-details.sh"
  }
}

resource "null_resource" "ansible_playbook" {
  count      = local.ansible_execution ? 1 : 0
  depends_on = [null_resource.prepare_deployer, module.hdb_node.dbnode-data-disk-att, module.jumpbox.vm-windows]

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
      "ansible-playbook -i ${local.ansible_path}/hosts.yml ~/sap-hana/deploy/ansible/sap_playbook.yml"
    ]
  }
}
