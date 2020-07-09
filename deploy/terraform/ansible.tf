/*-----------------------------------------------------------------------------8
  Ansible playbook:
    1. prepare-rti-files: copy required files for Ansible onto RTI
    2. ansible_playbook: run playbook
+--------------------------------------4--------------------------------------*/
resource "null_resource" "prepare_rti_files" {
  depends_on = [module.output_files.ansible-inventory, module.output_files.output-json, module.jumpbox.prepare-rti]

  triggers = {
    hosts     = sha1(local.file_hosts)
    hosts_yml = sha1(local.file_hosts_yml)
    output    = sha1(local.file_output)
  }

  connection {
    type        = "ssh"
    host        = module.jumpbox.rti-info.public_ip_address
    user        = module.jumpbox.rti-info.authentication.username
    private_key = module.jumpbox.rti-info.authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(module.jumpbox.rti-info.authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  # Copies output.json and inventory file for ansbile on RTI.
  provisioner "file" {
    source      = "${terraform.workspace}/ansible_config_files/"
    destination = "/home/${module.jumpbox.rti-info.authentication.username}"
  }

  # Copies Clustering Service Principal for ansbile on RTI.
  provisioner "file" {
    # Note: We provide a default empty clustering auth script content so this provisioner succeeds.
    # Later in the execution, the script is sourced, but will have no impact if it has been defaulted
    content     = fileexists("${terraform.workspace}/export-clustering-sp-details.sh") ? file("${terraform.workspace}/export-clustering-sp-details.sh") : "# default empty clustering auth script"
    destination = "/home/${module.jumpbox.rti-info.authentication.username}/export-clustering-sp-details.sh"
  }
}

resource "null_resource" "ansible_playbook" {
  count      = local.ansible_execution ? 1 : 0
  depends_on = [null_resource.prepare_rti_files, module.hdb_node.dbnode-data-disk-att, module.jumpbox.vm-windows]

  connection {
    type        = "ssh"
    host        = module.jumpbox.rti-info.public_ip_address
    user        = module.jumpbox.rti-info.authentication.username
    private_key = module.jumpbox.rti-info.authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(module.jumpbox.rti-info.authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  # Run Ansible Playbook on jumpbox if ansible_execution set to true
  provisioner "remote-exec" {
    inline = [
      # Registers the current deployment state with Azure's Metadata Service (IMDS)
      "curl -i -H \"Metadata: \"true\"\" -H \"user-agent: SAP AutoDeploy/${var.auto-deploy-version}; scenario=${var.scenario}; deploy-status=Terraform_finished\" http://169.254.169.254/metadata/instance?api-version=${var.api-version}",
      "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES",
      "export ANSIBLE_HOST_KEY_CHECKING=False",
      "source ~/export-clustering-sp-details.sh",
      "ansible-playbook -i hosts.yml ~/sap-hana/deploy/ansible/sap_playbook.yml"
    ]
  }
}
