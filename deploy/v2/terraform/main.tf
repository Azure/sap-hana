# Initalizes Azure rm provider
provider "azurerm" {
  version = "~> 2.0"
  features {}
}

# Setup common infrastructure
module "common_infrastructure" {
  source              = "./modules/common_infrastructure"
  is_single_node_hana = "true"
  databases           = var.databases
  infrastructure      = var.infrastructure
  jumpboxes           = var.jumpboxes
  options             = var.options
  software            = var.software
  ssh-timeout         = var.ssh-timeout
  sshkey              = var.sshkey
}

# Create Jumpboxes and RTI box
module "jumpbox" {
  source            = "./modules/jumpbox"
  databases         = var.databases
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  options           = var.options
  software          = var.software
  ssh-timeout       = var.ssh-timeout
  sshkey            = var.sshkey
  resource-group    = module.common_infrastructure.resource-group
  subnet-mgmt       = module.common_infrastructure.subnet-mgmt
  nsg-mgmt          = module.common_infrastructure.nsg-mgmt
  storage-bootdiag  = module.common_infrastructure.storage-bootdiag
  output-json       = module.output_files.output-json
  ansible-inventory = module.output_files.ansible-inventory
  random-id         = module.common_infrastructure.random-id
}

# Create HANA database nodes
module "hdb_node" {
  source           = "./modules/hdb_node"
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = var.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource-group   = module.common_infrastructure.resource-group
  subnet-sap-admin = module.common_infrastructure.subnet-sap-admin
  nsg-admin        = module.common_infrastructure.nsg-admin
  subnet-sap-db    = module.common_infrastructure.subnet-sap-db
  nsg-db           = module.common_infrastructure.nsg-db
  storage-bootdiag = module.common_infrastructure.storage-bootdiag
}

# Generate output files
module "output_files" {
  source                       = "./modules/output_files"
  databases                    = var.databases
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  options                      = var.options
  software                     = var.software
  ssh-timeout                  = var.ssh-timeout
  sshkey                       = var.sshkey
  storage-sapbits              = module.common_infrastructure.storage-sapbits
  nics-jumpboxes-windows       = module.jumpbox.nics-jumpboxes-windows
  nics-jumpboxes-linux         = module.jumpbox.nics-jumpboxes-linux
  public-ips-jumpboxes-windows = module.jumpbox.public-ips-jumpboxes-windows
  public-ips-jumpboxes-linux   = module.jumpbox.public-ips-jumpboxes-linux
  nics-dbnodes-admin           = module.hdb_node.nics-dbnodes-admin
  nics-dbnodes-db              = module.hdb_node.nics-dbnodes-db
  loadbalancers                = module.hdb_node.loadbalancers
}

resource "null_resource" "ansible_playbook" {
  depends_on = [module.hdb_node.dbnode-data-disk-att, module.jumpbox.prepare-rti, module.jumpbox.vm-windows]
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
      var.options.ansible_execution ? "ansible-playbook -i hosts ~/sap-hana/deploy/v2/ansible/sap_playbook.yml" : "ansible-playbook --version"
    ]
  }
}
