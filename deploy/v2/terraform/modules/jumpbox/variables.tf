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
  description = "Timeout for connection that used by provisioner"
  default     = "30s"
}

# Identify RTI by tags and save the public IP and index of the linux jumpboxes
locals {
  rti-pip = {
    for pip in azurerm_public_ip.public-ip-linux :
    "pip" => pip.ip_address...
    if pip.tags.PublicIPFor == "RTI"
  }.pip[0]
  rti-index = {
    for vm in azurerm_virtual_machine.vm-linux :
    "index" => tonumber(vm.tags.JumpboxIndex)...
    if vm.tags.JumpboxName == "RTI"
  }.index[0]
}
