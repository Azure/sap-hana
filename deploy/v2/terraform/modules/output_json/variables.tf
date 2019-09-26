variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "jumpboxes" {
  description = "Details of the jumpboxes"
}

variable "databases" {
  description = "Details of the HANA database nodes"
}

variable "nic-linux" {
  description = "Details of the Linux jumpbox NICs"
}

variable "nic-windows" {
  description = "Details of the Windows jumpbox NICs"
}

variable "nic-dbnode-admin" {
  description = "Details of the admin NIC of DB nodes"
}

variable "nic-dbnode-db" {
  description = "Details of the database NIC of DB nodes"
}

locals {
  windows-jumpbox-ips = var.nic-windows[*].private_ip_address
  linux-jumpbox-ips   = var.nic-linux[*].private_ip_address
  dbnode-admin-ips    = [for k, v in var.nic-dbnode-admin : v.private_ip_address]
  dbnode-db-ips       = [for k, v in var.nic-dbnode-db : v.private_ip_address]
  dbnodes             = flatten([for database in var.databases : [for node in database.nodes : { role = node.role, platform = database.platform, name = node.name }]])
}
