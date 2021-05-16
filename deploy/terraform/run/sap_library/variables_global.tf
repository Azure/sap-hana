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

variable "storage_account_sapbits" {
  description = "Details of the Storage account for storing sap bits"
  default     = {}
}
variable "storage_account_tfstate" {
  description = "Details of the Storage account for storing tfstate"
  default     = {}
}
variable "software" {
  description = "Details of software, downloader etc."
  default     = {}
}
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
        length(split("/", var.key_vault.kv_spn_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_user_id") ? (
        length(split("/", var.key_vault.kv_user_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_prvt_id") ? (
        length(split("/", var.key_vault.kv_prvt_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
  }


}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""
}

variable "deployment" {
  description = "The type of deployment"
  default = "update"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
  default = ""
}

