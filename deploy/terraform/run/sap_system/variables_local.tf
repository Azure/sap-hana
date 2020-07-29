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
  db_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") != "NONE"
  ]

  db-sid = length(local.db_list) == 0 ? "" : try(local.db_list[0].instance.sid, local.db_list[0].platform == "HANA" ? "HN1" : "OR1")

  app-sid = try(var.application.enable_deployment, false) ? try(var.application.sid, "") : ""

  // TODO: add sap_lansdscape ENV to the path if stored local, or remote in sap_libarary
  ansible_path = local.app-sid != "" ? local.app-sid : (local.db-sid != "" ? local.db-sid : ".")

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
}

locals {
  file_hosts     = fileexists("${terraform.workspace}/ansible_config_files/hosts") ? file("${terraform.workspace}/ansible_config_files/hosts") : ""
  file_hosts_yml = fileexists("${terraform.workspace}/ansible_config_files/hosts.yml") ? file("${terraform.workspace}/ansible_config_files/hosts.yml") : ""
  file_output    = fileexists("${terraform.workspace}/ansible_config_files/output.json") ? file("${terraform.workspace}/ansible_config_files/output.json") : ""
}

// Import deployer information for ansible.tf
locals {
  import_deployer = module.deployer.import_deployer
}
