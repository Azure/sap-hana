variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP library into"
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

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""
}

variable "deployer_statefile_foldername" {
  description = "Folder name of folder containing the terraform state file"
  default     = ""
}

variable "dns_label" {
  description = "DNS label"
  default     = ""
}