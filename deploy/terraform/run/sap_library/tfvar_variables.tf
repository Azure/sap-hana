/*

This block describes the variable for the infrastructure block 

*/

variable "environment" {
  type        = string
  description = "This is the environment name of the library"
  default     = ""
}


variable "codename" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = ""
}

variable "resourcegroup_name" {
  default = ""
}

variable "resourcegroup_arm_id" {
  default = ""
}

variable "resourcegroup_tags" {
  default = {}
}

/*

/*

This block describes the variable for the deployer block 

*/

variable "deployer_environment" {
  type        = string
  description = "This is the environment name of the deployer"
  default     = ""
}

variable "deployer_location" {
  type    = string
  default = ""
}

variable "deployer_vnet" {
  type    = string
  default = ""
}

variable "use_deployer" {
  default = true
}

/*
This block describes the variables for the key_vault section
*/

variable "user_keyvault_id" {
  default = ""
}

variable "automation_keyvault_id" {
  default = ""
}

variable "spn_keyvault_id" {
  default = ""
}

/*
This block describes the variables for the "SAPBits" storage account
*/


variable "library_sapmedia_arm_id" {
  default = ""
}

variable "library_sapmedia_account_tier" {
  default = "Standard"
}

variable "library_sapmedia_account_replication_type" {
  default = "LRS"
}

variable "library_sapmedia_account_kind" {
  default = "StorageV2"
}

variable "library_sapmedia_file_share_enable_deployment" {
  default = true
}

variable "library_sapmedia_file_share_is_existing" {
  default = false
}

variable "library_sapmedia_file_share_name" {
  default = "sapbits"
}
variable "library_sapmedia_blob_container_enable_deployment" {
  default = true
}

variable "library_sapmedia_blob_container_is_existing" {
  default = false
}

variable "library_sapmedia_blob_container_name" {
  default = "sapbits"
}


/*
This block describes the variables for the "TFState" storage account
*/


variable "library_terraform_state_arm_id" {
  default = ""
}

variable "library_terraform_state_account_tier" {
  default = "Standard"
}

variable "library_terraform_state_account_replication_type" {
  default = "LRS"
}

variable "library_terraform_state_account_kind" {
  default = "StorageV2"
}

variable "library_terraform_state_blob_container_is_existing" {
  default = false
}

variable "library_terraform_state_blob_container_name" {
  default = "tfstate"
}

variable "library_ansible_blob_container_is_existing" {
  default = false
}

variable "library_ansible_blob_container_name" {
  default = "ansible"
}

variable "use_private_endpoint" {
  default = false
}

