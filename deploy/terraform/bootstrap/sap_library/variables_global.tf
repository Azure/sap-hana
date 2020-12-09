variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP Library into"
  default     = {}
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
}

variable "key_vault" {
  description = "Import existing Azure Key Vaults"
  default     = {}
}
