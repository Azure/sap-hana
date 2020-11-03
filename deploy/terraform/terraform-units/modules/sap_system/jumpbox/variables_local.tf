variable "resource_group" {
  description = "Details of the resource group"
}

variable "storage_bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "output_json" {
  description = "Details of the output JSON"
}

variable "ansible_inventory" {
  description = "Details of the Ansible inventory"
}

variable "random_id" {
  description = "Random hex for creating unique Azure key vault name"
}

variable "deployer_tfstate" {
  description = "Deployer tfstate file"
}

locals {

  // Retrieve deployer information from tfstate file
  deployer_uai = var.deployer_tfstate.deployer_uai
  subnet_mgmt  = var.deployer_tfstate.subnet_mgmt
  nsg_mgmt     = var.deployer_tfstate.nsg_mgmt

  output_tf = jsondecode(var.output_json.content)

  # Linux jumpbox information
  vm_jump_linux = [
    for jumpbox in var.jumpboxes.linux : jumpbox
  ]

  # Windows jumpbox information
  vm_jump_win = [
    for jumpbox in var.jumpboxes.windows : jumpbox
  ]
}
