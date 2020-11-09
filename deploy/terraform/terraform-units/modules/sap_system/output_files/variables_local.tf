variable "infrastructure_w_defaults" {
  description = "infrasturcture dict with default values"
}

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

variable "hdb_sid" {
  description = "List of SIDs used when generating Load Balancers"
}

variable "hana_database_info" {
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
  description = "Updated anydb database json"
}

variable "software" {
  description = "Contain information about downloader, sapbits, etc."
  default     = {}
}

locals {

  ips_iscsi         = var.iscsi_private_ip
  ips_dbnodes_admin = [for key, value in var.nics_dbnodes_admin : value.private_ip_address]
  ips_dbnodes_db    = [for key, value in var.nics_dbnodes_db : value.private_ip_address]

  databases = [
    var.hana_database_info
  ]
  hdb_vms = flatten([
    for database in local.databases : flatten([
      [
        for dbnode in database.dbnodes : {
          role           = dbnode.role,
          platform       = database.platform,
          authentication = database.authentication,
          name           = dbnode.computername
        }
        if try(database.platform, "NONE") == "HANA"
      ],
      [
        for dbnode in database.dbnodes : {
          role           = dbnode.role,
          platform       = database.platform,
          authentication = database.authentication,
          name           = dbnode.computername
        }
        if try(database.platform, "NONE") == "HANA" && database.high_availability
      ]
    ])
    if database != {}
  ])

  ips_primary_scs = length(var.nics_scs_admin) > 0 ? var.nics_scs_admin : var.nics_scs
  ips_primary_app = length(var.nics_app_admin) > 0 ? var.nics_app_admin : var.nics_app
  ips_primary_web = length(var.nics_web_admin) > 0 ? var.nics_web_admin : var.nics_web

  ips_scs = [for key, value in local.ips_primary_scs : value.private_ip_address]
  ips_app = [for key, value in local.ips_primary_app : value.private_ip_address]
  ips_web = [for key, value in local.ips_primary_web : value.private_ip_address]

  ips_primary_anydb = length(var.nics_anydb_admin) > 0 ? var.nics_anydb_admin : var.nics_anydb
  ips_anydbnodes    = [for key, value in local.ips_primary_anydb : value.private_ip_address]

  anydatabases = [
    var.any_database_info
  ]
  anydb_vms = flatten([
    for adatabase in local.anydatabases : flatten([
      [
        for dbnode in adatabase.dbnodes : {
          role           = dbnode.role,
          platform       = upper(adatabase.platform),
          authentication = adatabase.authentication,
          name           = dbnode.name
        }
        if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(adatabase.platform, "NONE")))
      ],
      [
        for dbnode in adatabase.dbnodes : {
          role           = dbnode.role,
          platform       = upper(adatabase.platform),
          authentication = adatabase.authentication,
          name           = dbnode.name
        }
        if adatabase.high_availability && contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(adatabase.platform, "NONE")))
      ]
    ])
    if adatabase != {}
  ])

  // Downloader for Ansible use
  sap_user     = try(var.software.downloader.credentials.sap_user, "sap_smp_user")
  sap_password = try(var.software.downloader.credentials.sap_password, "sap_smp_password")

  hdb_versions = [
    for scenario in try(var.software.downloader.scenarios, []) : scenario.product_version
    if scenario.scenario_type == "DB"
  ]
  hdb_version = try(local.hdb_versions[0], "2.0")

  downloader = merge({
    credentials = {
      sap_user     = local.sap_user,
      sap_password = local.sap_password
    }
    },
    {
      scenarios = [
        {
          scenario_type   = "DB",
          product_name    = "HANA",
          product_version = local.hdb_version,
          os_type         = "LINUX_X64",
          os_version      = "SLES12.3",
          components = [
            "PLATFORM"
          ]
        },
        {
          scenario_type = "RTI",
          product_name  = "RTI",
          os_type       = "LINUX_X64"
        },
        {
          scenario_type = "BASTION",
          os_type       = "NT_X64"
        },
        {
          scenario_type = "BASTION",
          os_type       = "LINUX_X64"
        }
      ],
      debug = {
        enabled = false,
        cert    = "charles.pem",
        proxies = {
          http  = "http://127.0.0.1:8888",
          https = "https://127.0.0.1:8888"
        }
      }
  })
}
