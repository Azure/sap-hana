variable "resource-group" {
  description = "Details of the resource group"
}

variable "subnet-mgmt" {
  description = "Details of the management subnet"
}

variable "nsg-mgmt" {
  description = "Details of the management NSG"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "output-json" {
  description = "Details of the output JSON"
}

variable "ansible-inventory" {
  description = "Details of the Ansible inventory"
}

variable "random-id" {
  description = "Random hex for creating unique Azure key vault name"
}

variable "deployer_tfstate" {
  description = "Deployer tfstate file"
}

locals {

  // Retrieve deployer information from tfstate file
  deployer-uai = var.deployer_tfstate.deployer_uai

  output-tf = jsondecode(var.output-json.content)

  # Linux jumpbox information
  vm-jump-linux = [
    for jumpbox in var.jumpboxes.linux : jumpbox
  ]

  # Windows jumpbox information
  vm-jump-win = [
    for jumpbox in var.jumpboxes.windows : jumpbox
  ]
}
