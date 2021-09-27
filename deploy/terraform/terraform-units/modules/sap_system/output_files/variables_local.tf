
variable "nics_dbnodes_admin" {
  description = "Admin NICs of HANA database nodes"
}

variable "nics_dbnodes_db" {
  description = "NICs of HANA database nodes"
}

variable "iscsi_private_ip" {
  description = "Private ips of iSCSIs"
}

variable "loadbalancers" {
  description = "List of LoadBalancers created for HANA Databases"
}

variable "sap_sid" {
  description = "SAP SID"
}

variable "db_sid" {
  description = "Database SID"
}

variable "hana_database_info" {
  sensitive   = false
  description = "Updated hana database json"
}

variable "nics_scs" {
  description = "List of NICs for the SCS Application VMs"
}

variable "nics_app" {
  description = "List of NICs for the Application Instance VMs"
}

variable "nics_web" {
  description = "List of NICs for the Web dispatcher VMs"
}

# Any DB
variable "nics_anydb" {
  description = "List of NICs for the AnyDB VMs"
}

variable "nics_scs_admin" {
  description = "List of NICs for the SCS Application VMs"
}

variable "nics_app_admin" {
  description = "List of NICs for the Application Instance VMs"
}

variable "nics_web_admin" {
  description = "List of NICs for the Web dispatcher VMs"
}

// Any DB
variable "nics_anydb_admin" {
  description = "List of Admin NICs for the anyDB VMs"
}

variable "random_id" {
  description = "Random hex string"
}

variable "anydb_loadbalancers" {
  description = "List of LoadBalancers created for HANA Databases"
}

variable "any_database_info" {
  sensitive   = false
  description = "Updated anydb database json"
}

variable "software" {
  description = "Contain information about downloader, sapbits, etc."
  default     = {}
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "tfstate_resource_id" {
  description = "Resource ID for tf state file"
}

variable "app_tier_os_types" {
  description = "Defines the app tier os types"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "sid_kv_user_id" {
  description = "Defines the names for the resources"
}

variable "disks" {
  description = "List of disks"
}

variable "use_local_credentials" {
  description = "SDU has unique credentials"
}

variable "authentication_type" {
  description = "VM Authentication type"
  default     = "key"

}

variable "db_ha" {
  description = "Is the DB deployment highly available"
  default     = false
}

variable "scs_ha" {
  description = "Is the SCS deployment highly available"
  default     = false
}

variable "ansible_user" {
  description = "The ansible remote user account to use"
  default     = "azureadm"
}

variable "db_lb_ip" {
  description = "DB Load Balancer IP"
  default     = ""
}

variable "scs_lb_ip" {
  description = "SCS Load Balancer IP"
  default     = ""
}

variable "sap_mnt" {
  description = "ANF Volume for SAP mount"
  default     = ""
}

variable "sap_transport" {
  description = "ANF Volume for SAP Transport"
  default     = ""
}


variable "database_admin_ips" {
  description = "List of Admin NICs for the DB VMs"
}

locals {

  tfstate_resource_id          = try(var.tfstate_resource_id, "")
  tfstate_storage_account_name = split("/", local.tfstate_resource_id)[8]
  ansible_container_name       = try(var.naming.resource_suffixes.ansible, "ansible")

  kv_name = split("/", var.sid_kv_user_id)[8]

  landscape_tfstate = var.landscape_tfstate
  ips_iscsi         = var.iscsi_private_ip
  ips_dbnodes_admin = [for key, value in var.nics_dbnodes_admin : value.private_ip_address]
  ips_dbnodes_db    = [for key, value in var.nics_dbnodes_db : value.private_ip_address]

  iscsi = {
    iscsi_count = length(local.ips_iscsi)
    authentication = {
      type     = local.landscape_tfstate.iscsi_authentication_type
      username = local.landscape_tfstate.iscsi_authentication_username
    }
  }

  databases = [
    var.hana_database_info
  ]
  hdb_vms = flatten([
    for database in local.databases : flatten([
      [

        for dbnode in database.dbnodes : {
          role      = dbnode.role,
          platform  = database.platform,
          name      = dbnode.computername,
          auth_type = try(database.auth_type, "key")
        }
        if try(database.platform, "NONE") == "HANA"
      ],
      [
        for dbnode in database.dbnodes : {
          role      = dbnode.role,
          platform  = database.platform,
          name      = dbnode.computername,
          auth_type = try(database.auth_type, "key")
        }
        if try(database.platform, "NONE") == "HANA" && database.high_availability
      ]
    ])
    if database != {}
  ])

  ips_primary_scs = var.nics_scs
  ips_primary_app = var.nics_app
  ips_primary_web = var.nics_web

  ips_scs = [for key, value in local.ips_primary_scs : value.private_ip_address]
  ips_app = [for key, value in local.ips_primary_app : value.private_ip_address]
  ips_web = [for key, value in local.ips_primary_web : value.private_ip_address]

  ips_primary_anydb = var.nics_anydb
  ips_anydbnodes    = [for key, value in local.ips_primary_anydb : value.private_ip_address]

  anydatabases = [
    var.any_database_info
  ]
  anydb_vms = flatten([
    for adatabase in local.anydatabases : flatten([
      [

        for dbnode in adatabase.dbnodes : {
          role      = dbnode.role,
          platform  = upper(adatabase.platform),
          name      = dbnode.computername,
          auth_type = try(adatabase.auth_type, "key")

        }
        if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(adatabase.platform, "NONE")))
      ],
      [
        for dbnode in adatabase.dbnodes : {
          role      = dbnode.role,
          platform  = upper(adatabase.platform),
          name      = dbnode.computername,
          auth_type = try(adatabase.auth_type, "key")
        }
        if adatabase.high_availability && contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(adatabase.platform, "NONE")))
      ]
    ])
    if adatabase != {}
  ])

  secret_prefix = var.use_local_credentials ? var.naming.prefix.SDU : var.naming.prefix.VNET
  dns_label     = try(var.landscape_tfstate.dns_label, "")



}
