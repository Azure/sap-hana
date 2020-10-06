variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "v2"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "HANA Database"
}

# Set defaults
locals {

  ansible_path = "${module.saplibrary.environment}_${module.saplibrary.sid}"

  # Options
  enable_secure_transfer = try(var.options.enable_secure_transfer, true)
  ansible_execution      = try(var.options.ansible_execution, false)
  enable_prometheus      = try(var.options.enable_prometheus, true)

  # Update options with defaults
  options = merge(var.options, {
    enable_secure_transfer = local.enable_secure_transfer,
    ansible_execution      = local.ansible_execution,
    enable_prometheus      = local.enable_prometheus
  })

  file_hosts     = fileexists("${terraform.workspace}/ansible_config_files/hosts") ? file("${terraform.workspace}/ansible_config_files/hosts") : ""
  file_hosts_yml = fileexists("${terraform.workspace}/ansible_config_files/hosts.yml") ? file("${terraform.workspace}/ansible_config_files/hosts.yml") : ""
  file_output    = fileexists("${terraform.workspace}/ansible_config_files/output.json") ? file("${terraform.workspace}/ansible_config_files/output.json") : ""

  // Import deployer information for ansible.tf
  import_deployer = module.deployer.import_deployer

  # SAP vnet
  var_infra       = try(var.infrastructure, {})
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false

  vnet_sap_name = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, "sap")
  vnet_nr_parts = length(split("-", local.vnet_sap_name))
  // Default naming of vnet has multiple parts. Taking the second-last part as the name 
  vnet_sap_name_part = try(substr(upper(local.vnet_sap_name), -5, 5), "") == "-VNET" ? substr(split("-", local.vnet_sap_name)[(local.vnet_nr_parts - 2)], 0, 7) : local.vnet_sap_name

  //SID determination

  hana-databases = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  // Filter the list of databases to only AnyDB platform entries
  // Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in var.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  hdb            = try(local.hana-databases[0], {})
  hdb_ins        = try(local.hdb.instance, {})
  hanadb_sid     = try(local.hdb_ins.sid, "HDB") // HANA database sid from the Databases array for use as reference to LB/AS
  anydb_platform = try(local.anydb-databases[0].platform, "NONE")
  anydb_sid      = (length(local.anydb-databases) > 0) ? try(local.anydb-databases[0].instance.sid, lower(substr(local.anydb_platform, 0, 3))) : lower(substr(local.anydb_platform, 0, 3))
  db_sid         = length(local.hana-databases) > 0 ? local.hanadb_sid : local.anydb_sid
  sap_sid        = upper(try(var.application.sid, local.db_sid))

  app_ostype          = try(var.application.os.os_type, "LINUX")
  db_ostype           = try(var.databases[0].os.os_type, "LINUX")
  db_server_count     = try(length(var.databases[0].dbnodes), 1)
  app_server_count    = try(var.application.application_server_count, 0)
  webdispatcher_count = try(var.application.webdispatcher_count, 0)
  scs_server_count    = try(var.application.scs_high_availability, false) ? 2 : 1

}
