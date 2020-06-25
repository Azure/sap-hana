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

variable "jumpboxes-linux" {
  description = "linux jumpboxes with rti"
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

variable "nics-iscsi" {
  description = "NICs of ISCSI target servers"
}

variable "loadbalancers" {
  description = "List of LoadBalancers created for HANA Databases"
}

variable "hdb-sid" {
  description = "List of SIDs used when generating Load Balancers"
}

variable "hana-database-info" {
  description = "Updated hana database json"
}

variable "nics-scs" {
  description = "List of NICs for the SCS Application VMs"
}

variable "nics-app" {
  description = "List of NICs for the Application Instance VMs"
}

variable "nics-web" {
  description = "List of NICs for the Web dispatcher VMs"
}

locals {
  ips-iscsi                    = var.nics-iscsi[*].private_ip_address
  ips-jumpboxes-windows        = var.nics-jumpboxes-windows[*].private_ip_address
  ips-jumpboxes-linux          = var.nics-jumpboxes-linux[*].private_ip_address
  public-ips-jumpboxes-windows = var.public-ips-jumpboxes-windows[*].ip_address
  public-ips-jumpboxes-linux   = var.public-ips-jumpboxes-linux[*].ip_address
  ips-dbnodes-admin            = [for key, value in var.nics-dbnodes-admin : value.private_ip_address]
  ips-dbnodes-db               = [for key, value in var.nics-dbnodes-db : value.private_ip_address]
  databases = [
    var.hana-database-info
  ]
  hdb_vms = flatten([
    for database in local.databases : flatten([
      [
        for dbnode in database.dbnodes : {
          role           = dbnode.role,
          platform       = database.platform,
          authentication = database.authentication,
          name           = "${dbnode.name}-0"
        }
        if try(database.platform, "NONE") == "HANA"
      ],
      [
        for dbnode in database.dbnodes : {
          role           = dbnode.role,
          platform       = database.platform,
          authentication = database.authentication,
          name           = "${dbnode.name}-1"
        }
        if try(database.platform, "NONE") == "HANA" && database.high_availability
      ]
    ])
    if database != {}
  ])
  ips-scs = [for key, value in var.nics-scs : value.private_ip_address]
  ips-app = [for key, value in var.nics-app : value.private_ip_address]
  ips-web = [for key, value in var.nics-web : value.private_ip_address]
}
