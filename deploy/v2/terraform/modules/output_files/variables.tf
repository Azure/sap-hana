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
  description = "Details of the information required to download SAP installation media"
}

variable "options" {
  description = "Configuration options"
}

variable "nics-jumpboxes-linux" {
  description = "NICs of the Linux jumpboxes"
}

variable "nics-jumpboxes-windows" {
  description = "NICs of the Windows jumpboxes"
}

variable "public-ips-jumpboxes-linux" {
  description = "Public IPs of the Linux jumpboxes"
}

variable "public-ips-jumpboxes-windows" {
  description = "Public IPs of the Windows jumpboxes"
}

variable "nics-dbnodes-admin" {
  description = "Admin NICs of HANA database nodes"
}

variable "nics-dbnodes-db" {
  description = "NICs of HANA database nodes"
}

variable "storage-sapbits" {
  description = "Details of the storage account for SAP bits"
}

locals {
  ips-jumpboxes-windows        = var.nics-jumpboxes-windows[*].private_ip_address
  ips-jumpboxes-linux          = var.nics-jumpboxes-linux[*].private_ip_address
  public-ips-jumpboxes-windows = var.public-ips-jumpboxes-windows[*].ip_address
  public-ips-jumpboxes-linux   = var.public-ips-jumpboxes-linux[*].ip_address
  ips-dbnodes-admin            = [for key, value in var.nics-dbnodes-admin : value.private_ip_address]
  ips-dbnodes-db               = [for key, value in var.nics-dbnodes-db : value.private_ip_address]
  dbnodes                      = flatten([for database in var.databases : [for dbnode in database.dbnodes : { role = dbnode.role, platform = database.platform, authentication = database.authentication, name = dbnode.name }]])
}
