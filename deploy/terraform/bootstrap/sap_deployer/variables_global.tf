/*
Description:

  Define input variables.
*/

variable "deployers" {
  description = "Details of the list of deployer(s)"
  default     = [{}]
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the deployer into"
  default     = {}

  validation {
    condition = (
      length(trimspace(var.infrastructure.region)) != 0
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      length(trimspace(var.infrastructure.environment)) != 0
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.management.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.address_space, ""))) != 0
    )
    error_message = "Either the arm_id or address_space of the VNet must be specified in the infrastructure.vnets.management block."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.prefix, ""))) != 0
    )
    error_message = "Either the arm_id or prefix of the subnet must be specified in the infrastructure.vnets.management.subnet_mgmt block."
  }

}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "authentication" {
  description = "Details of ssh key pair"
  default     = {}
}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}

variable "firewall_deployment" {
  description = "Boolean flag indicating if an Azure Firewall should be deployed"
  default     = false
}

variable "firewall_rule_subnets" {
  description = "List of subnets that are part of the firewall rule"
  default     = []
}

variable "firewall_allowed_ipaddresses" {
  description = "List of allowed IP addresses to be part of the firewall rule"
  default     = []
}

variable "assign_subscription_permissions" {
  description = "Assign permissions on the subscription"
  default = true
}
