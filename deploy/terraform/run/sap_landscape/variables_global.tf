variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
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

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.name, ""))) != 0
    )
    error_message = "Please specify the logical VNet identifier in the infrastructure.vnets.sap.name field. For deployments prior to version '2.3.3.1' please use the identifier 'sap'."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.address_space, ""))) != 0
    )
    error_message = "Either the arm_id or (name and address_space) of the Virtual Network must be specified in the infrastructure.vnets.sap block."
  }
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "authentication" {
  description = "Details of ssh key pair"
  default = {
    username            = "azureadm",
    path_to_public_key  = "",
    path_to_private_key = ""

  }

  validation {
    condition = (
      length(var.authentication) >= 1
    )
    error_message = "Either ssh keys or user credentials must be specified."
  }
  validation {
    condition = (
      length(trimspace(var.authentication.username)) != 0
    )
    error_message = "The default username for the Virtual machines must be specified."
  }
}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default = {
    kv_user_id = "",
    kv_prvt_id = "",
  }
}

variable "diagnostics_storage_account" {
  description = "Storage account information for diagnostics account"
  default = {
    arm_id = ""
  }
}

variable "witness_storage_account" {
  description = "Storage account information for witness storage account"
  default = {
    arm_id = ""
  }
}
