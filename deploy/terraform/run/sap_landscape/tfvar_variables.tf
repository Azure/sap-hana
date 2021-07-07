/*

This block describes the variable for the infrastructure block in the json file

*/

variable "environment" {
  type        = string
  description = "This is the environment name of the deployer"
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

/*

This block describes the variables for the VNet block in the json file

*/

variable "sap_network_name" {
  default = ""
}

variable "sap_network_arm_id" {
  default = ""
}

variable "sap_network_address_space" {
  default = ""
}

/* admin subnet information */

variable "sap_admin_subnet_name" {
  default = ""
}

variable "sap_admin_subnet_arm_id" {
  default = ""
}

variable "sap_admin_subnet_address_prefix" {
  default = ""
}

variable "sap_admin_subnet_nsg_name" {
  default = ""
}

variable "sap_admin_subnet_nsg_arm_id" {
  default = ""
}

/* db subnet information */

variable "sap_db_subnet_name" {
  default = ""
}

variable "sap_db_subnet_arm_id" {
  default = ""
}

variable "sap_db_subnet_address_prefix" {
  default = ""
}

variable "sap_db_subnet_nsg_name" {
  default = ""
}

variable "sap_db_subnet_nsg_arm_id" {
  default = ""
}

/* app subnet information */

variable "sap_app_subnet_name" {
  default = ""
}

variable "sap_app_subnet_arm_id" {
  default = ""
}

variable "sap_app_subnet_address_prefix" {
  default = ""
}

variable "sap_app_subnet_nsg_name" {
  default = ""
}

variable "sap_app_subnet_nsg_arm_id" {
  default = ""
}

/* web subnet information */

variable "sap_web_subnet_name" {
  default = ""
}

variable "sap_web_subnet_arm_id" {
  default = ""
}

variable "sap_web_subnet_address_prefix" {
  default = ""
}

variable "sap_web_subnet_nsg_name" {
  default = ""
}

variable "sap_web_subnet_nsg_arm_id" {
  default = ""
}

/* iscsi subnet information */

variable "sap_iscsi_subnet_name" {
  default = ""
}

variable "sap_iscsi_subnet_arm_id" {
  default = ""
}

variable "sap_iscsi_subnet_address_prefix" {
  default = ""
}

variable "sap_iscsi_subnet_nsg_name" {
  default = ""
}

variable "sap_iscsi_subnet_nsg_arm_id" {
  default = ""
}

variable "iscsi_count" {
  default = 0
}

variable "iscsi_size" {
  default = ""
}

variable "iscsi_useDHCP" {
  default = false
}

variable "iscsi_image" {
  default = {
    "source_image_id" = ""
    "publisher"       = "suse"
    "offer"           = "sles-sap-12-sp5"
    "sku"             = "gen1"
    "version"         = "latest"
  }
}

variable "iscsi_authentication_type" {
  default = "key"
}

variable "iscsi_authentication_username" {
  default = "azureadm"
}


variable "iscsi_nic_ips" {
  default = []
}
/*
This block describes the variables for the key_vault section block in the json file
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
This block describes the variables for the authentication section block in the json file
*/


variable "automation_username" {
  default = "azureadm"
}

variable "automation_password" {
  default = ""
}

variable "automation_path_to_public_key" {
  default = ""
}

variable "automation_path_to_private_key" {
  default = ""
}

variable "diagnostics_storage_account_arm_id" {
  default = ""
}


variable "witness_storage_account_arm_id" {
  default = ""
}
