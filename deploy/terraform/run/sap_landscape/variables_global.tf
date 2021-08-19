variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
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

}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default = {
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

variable "deployment" {
  description = "The type of deployment"
  default     = "update"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
  default     = ""
}

variable "dns_label" {
  description = "DNS label"
  default     = ""
}

variable "dns_resource_group_name" {
  description = "DNS resource group name"
  default     = ""
}