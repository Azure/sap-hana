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
  hana-sid = length([
    for database in var.databases : database
    if database.platform == "HANA"
  ]) > 0 ? element([
    for database in var.databases : database.instance.sid
    if database.platform == "HANA"
  ], 0) : ""
}
