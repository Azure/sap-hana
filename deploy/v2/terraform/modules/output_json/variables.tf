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

# Imports HANA database sizing information
locals {
  sizes = jsondecode(file("${path.root}/../hdb_sizes.json"))
}

locals {
  ips-windows-jumpboxes = var.nics-windows-jumpboxes[*].private_ip_address
  ips-linux-jumpboxes   = var.nics-linux-jumpboxes[*].private_ip_address
  ips-dbnodes-admin     = [for key, value in var.nics-dbnodes-admin : value.private_ip_address]
  ips-dbnodes-db        = [for key, value in var.nics-dbnodes-db : value.private_ip_address]
  dbnodes               = flatten([for database in var.databases : [for dbnode in database.dbnodes : { role = dbnode.role, platform = database.platform, name = dbnode.name }]])
}
