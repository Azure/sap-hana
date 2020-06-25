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
  hdb_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]
  hana-sid = try(local.hdb_list[0].instance.sid, "")
}

locals {
  file_hosts     = fileexists("${terraform.workspace}/ansible_config_files/hosts") ? file("${terraform.workspace}/ansible_config_files/hosts") : ""
  file_hosts_yml = fileexists("${terraform.workspace}/ansible_config_files/hosts.yml") ? file("${terraform.workspace}/ansible_config_files/hosts.yml") : ""
  file_output    = fileexists("${terraform.workspace}/ansible_config_files/output.json") ? file("${terraform.workspace}/ansible_config_files/output.json") : ""
}
