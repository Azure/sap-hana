variable "jumpboxes" {
  description = "Details of the jumpboxes"
}

variable "databases" {
  description = "Details of the databases"
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

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

variable "sshkey" {
  description = "Details of ssh key pair"
}

variable "output-json" {
  description = "Details of the output JSON"
}

variable "ansible-inventory" {
  description = "Details of the Ansible inventory"
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
}

# RTI IP and authentication details
locals {
  output-tf = jsondecode(var.output-json.content)
  rti-info = [
    for jumpbox-linux in local.output-tf.jumpboxes.linux : {
      public_ip_address = jumpbox-linux.public_ip_address,
      authentication    = jumpbox-linux.authentication
    }
    if jumpbox-linux.destroy_after_deploy == "true"
  ]
}
