variable "infrastructure" {}
variable "options" {}
variable "authentication" {}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}

variable "diagnostics_storage_account" {
  description = "Storage account information for diagnostics account"
}

variable "witness_storage_account" {
  description = "Storage account information for diagnostics account"
}
