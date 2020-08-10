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

  ansible_path = "${module.saplibrary.landscape_id}_${module.saplibrary.sid}"

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
