variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP library into"
  default     = {}

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.region, ""))) != 0
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.environment, ""))) != 0
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }
}

variable "storage_account_sapbits" {}
variable "storage_account_tfstate" {}
variable "software" {}
variable "deployer" {
  description = "Details of deployer"
  default     = {}

  validation {
    condition = (
      length(trimspace(try(var.deployer.region, ""))) != 0
    )
    error_message = "The region must be specified in the deployer.region field."
  }

  validation {
    condition = (
      length(trimspace(try(var.deployer.environment, ""))) != 0
    )
    error_message = "The environment must be specified in the deployer.environment field."
  }

  validation {
    condition = (
      length(trimspace(try(var.deployer.vnet, ""))) != 0
    )
    error_message = "The deployer VNet name must be specified in the deployer.vnet field."
  }

}
variable "key_vault" {
  description = "Import existing Azure Key Vaults"
  default     = {}

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_spn_id") ? (
        length(split("/", var.key_vault.kv_spn_id)) == 9 || length(var.key_vault.kv_spn_id) == 0) : (
        true
      )
    )
    error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_user_id") ? (
        length(split("/", var.key_vault.kv_user_id)) == 9) || length(var.key_vault.kv_user_id) == 0 : (
        true
      )
    )
    error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_prvt_id") ? (
        length(split("/", var.key_vault.kv_prvt_id)) == 9) || length(var.key_vault.kv_prvt_id) == 0 : (
        true
      )
    )
    error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
  }

}

variable "dns_label" {}
