/*
Description:

  Define input variables.
*/

variable "infrastructure" {
   validation {
    condition = (
      contains(keys(var.infrastructure), "region") ? (
        length(trimspace(var.infrastructure.region)) != 0) : (
        true
      )
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure), "environment") ? (
        length(trimspace(var.infrastructure.environment)) != 0) : (
        true
      )
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure), "vnets") ? (
        length(trimspace(try(var.infrastructure.vnets.management.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.address_space, ""))) != 0) : (
        true
      )
    )
    error_message = "Either the arm_id or address_space of the VNet must be specified in the infrastructure.vnets.management block."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure), "vnets") ? (
        length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.prefix, ""))) != 0) : (
        true
      )
    )
    error_message = "Either the arm_id or prefix of the subnet must be specified in the infrastructure.vnets.management.subnet_mgmt block."
  }
}
variable "deployers" {}
variable "options" {}
variable "ssh-timeout" {}
variable "authentication" {
}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
    validation {
    condition = (
      contains(keys(var.key_vault), "kv_spn_id") ? (
        length(split("/", var.key_vault.kv_spn_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
  }
}
