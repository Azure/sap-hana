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
}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default=""
}

variable "deployer_statefile_foldername" {
  description = "Folder name of folder containing the terraform state file"
  default = ""
}
