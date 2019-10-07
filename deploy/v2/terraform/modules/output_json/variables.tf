variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "jumpboxes" {
  description = "Details of the jumpboxes"
}

variable "databases" {
  description = "Details of the HANA database nodes"
}

variable "software" {
  description = "Details of the infrastructure components required for SAP installation"
}

variable "nics-linux-jumpboxes" {
  description = "Details of the Linux jumpbox NICs"
}

variable "nics-windows-jumpboxes" {
  description = "Details of the Windows jumpbox NICs"
}

variable "nics-dbnodes-admin" {
  description = "Details of the admin NIC of DB nodes"
}

variable "nics-dbnodes-db" {
  description = "Details of the database NIC of DB nodes"
}

variable "storage-sapbits" {
  description = "Details of the storage account for SAP bits"
}

variable "tf-output-file-path" {
  description = "Path of the Terraform output file"
}

locals {
  ips-windows-jumpboxes = var.nics-windows-jumpboxes[*].private_ip_address
  ips-linux-jumpboxes   = var.nics-linux-jumpboxes[*].private_ip_address
  ips-dbnodes-admin     = [for k, v in var.nics-dbnodes-admin : v.private_ip_address]
  ips-dbnodes-db        = [for k, v in var.nics-dbnodes-db : v.private_ip_address]
  dbnodes               = flatten([for database in var.databases : [for node in database.nodes : { role = node.role, platform = database.platform, name = node.name }]])
}
